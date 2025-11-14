from rest_framework import generics, filters, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q
from django.utils import timezone
from django.http import HttpResponse, Http404, FileResponse
from django.shortcuts import get_object_or_404
from django.views.decorators.http import require_http_methods
import os
import mimetypes
from .models import College, Branch, Subject, PreviousYearQuestion, UserRole
from .serializers import (
    CollegeSerializer, BranchSerializer, SubjectSerializer, 
    PreviousYearQuestionSerializer, UserRoleSerializer,
    PYQUploadSerializer, PYQModerationSerializer
)
from .permissions import RoleBasedPermissionMixin


class CollegeListView(generics.ListAPIView):
    """
    GET /api/colleges/ - List all active colleges
    """
    serializer_class = CollegeSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'location']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']

    def get_queryset(self):
        return College.objects.filter(is_active=True)

class BranchListView(generics.ListAPIView):
    """
    GET /api/branches/?college_id= - Get branches for a specific college
    """
    serializer_class = BranchSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'code']
    ordering_fields = ['name']
    ordering = ['name']

    def get_queryset(self):
        queryset = Branch.objects.select_related('college', 'created_by').filter(is_active=True)
        college_id = self.request.query_params.get('college_id')
        
        if college_id:
            queryset = queryset.filter(college_id=college_id)
        
        return queryset


class SubjectListView(generics.ListAPIView):
    """
    GET /api/subjects/?branch_id= - Get subjects for a specific branch
    GET /api/subjects/?college_id= - Get subjects for all branches in a college
    GET /api/subjects/?college_id=&branch_id= - Get subjects for a specific branch (branch_id takes precedence)
    """
    serializer_class = SubjectSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'code']
    ordering_fields = ['name']
    ordering = ['name']

    def get_queryset(self):
        queryset = Subject.objects.select_related('branch', 'branch__college', 'created_by').filter(is_active=True)
        branch_id = self.request.query_params.get('branch_id')
        college_id = self.request.query_params.get('college_id')
        
        if branch_id:
            # If branch_id is provided, filter by specific branch
            queryset = queryset.filter(branch_id=branch_id)
        elif college_id:
            # If only college_id is provided, get subjects from all branches in that college
            queryset = queryset.filter(branch__college_id=college_id)
        
        return queryset


class PreviousYearQuestionListView(generics.ListAPIView):
    """
    GET /api/pyqs/?subject_id=&year=&semester=&regulation= - Get filtered PYQs
    """
    serializer_class = PreviousYearQuestionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter, DjangoFilterBackend]
    search_fields = ['subject__name', 'regulation']
    ordering_fields = ['year', 'semester', 'uploaded_at']
    ordering = ['-year', 'semester']

    def get_queryset(self):
        queryset = PreviousYearQuestion.objects.select_related(
            'subject', 'subject__branch', 'subject__branch__college', 'uploaded_by', 'reviewed_by'
        )
        
        # Only show approved PYQs to regular users, but moderators can see all
        if not self.request.user.is_superuser:
            # Check if user can moderate for any college
            user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
            can_moderate_any = False
            for college in user_colleges:
                if RoleBasedPermissionMixin.can_moderate_pyqs(self.request.user, college):
                    can_moderate_any = True
                    break
            
            if not can_moderate_any:
                queryset = queryset.filter(status='approved')
        
        # Filter by query parameters
        subject_id = self.request.query_params.get('subject_id')
        year = self.request.query_params.get('year')
        semester = self.request.query_params.get('semester')
        regulation = self.request.query_params.get('regulation')
        
        if subject_id:
            queryset = queryset.filter(subject_id=subject_id)
        
        if year:
            queryset = queryset.filter(year=year)
        
        if semester:
            queryset = queryset.filter(semester=semester)
        
        if regulation:
            queryset = queryset.filter(regulation__icontains=regulation)
        
        return queryset


class PYQUploadView(generics.CreateAPIView):
    """
    POST /api/pyqs/upload/ - Upload a new PYQ (any authenticated user can upload)
    """
    serializer_class = PYQUploadSerializer
    permission_classes = [IsAuthenticated]
    def perform_create(self, serializer):
        serializer.save(uploaded_by=self.request.user)


class PYQModerationView(generics.UpdateAPIView):
    """
    PATCH /api/pyqs/<id>/moderate/ - Moderate a PYQ (approve/reject)
    """
    serializer_class = PYQModerationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PreviousYearQuestion.objects.all()

    def perform_update(self, serializer):
        pyq = self.get_object()
        college = pyq.subject.branch.college
        
        # Check if user can moderate for this college
        if not RoleBasedPermissionMixin.can_moderate_pyqs(self.request.user, college):
            raise PermissionDenied("You don't have permission to moderate PYQs for this college")
        
        serializer.save()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_role_info(request):
    """
    GET /api/user-role-info/ - Get current user's role information
    """
    user = request.user
    colleges = RoleBasedPermissionMixin.get_user_colleges(user)
    
    roles = []
    for college in colleges:
        user_role = RoleBasedPermissionMixin.get_user_role(user, college)
        roles.append({
            'college_id': college.id,
            'college_name': college.name,
            'role': user_role,
            'can_manage': RoleBasedPermissionMixin.can_manage_college(user, college),
            'can_moderate': RoleBasedPermissionMixin.can_moderate_pyqs(user, college)
        })
    
    return Response({
        'user_id': user.id,
        'username': user.username,
        'email': user.email,
        'is_superuser': user.is_superuser,
        'college_roles': roles
    })


class UserRoleListView(generics.ListAPIView):
    """
    GET /api/user-roles/?college_id= - List user roles for a college (admin/superadmin only)
    """
    serializer_class = UserRoleSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['user__username', 'user__email']
    ordering = ['college', 'role', 'user']

    def get_queryset(self):
        college_id = self.request.query_params.get('college_id')
        
        if not college_id:
            return UserRole.objects.none()
        
        try:
            college = College.objects.get(id=college_id)
        except College.DoesNotExist:
            return UserRole.objects.none()
        
        # Check if user can manage this college
        if not RoleBasedPermissionMixin.can_manage_college(self.request.user, college):
            return UserRole.objects.none()
        
        return UserRole.objects.filter(college=college, is_active=True).select_related('user', 'college', 'assigned_by')


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pyq_download(request, pk):
    """
    GET /api/pyqs/<id>/download/ - Download or view PYQ PDF file
    """
    try:
        pyq = get_object_or_404(PreviousYearQuestion, pk=pk)
        
        # Only check if PYQ is approved for regular users
        if not request.user.is_superuser:
            # Check if user can moderate for the college
            college = pyq.subject.branch.college
            if not RoleBasedPermissionMixin.can_moderate_pyqs(request.user, college):
                # Regular user - only allow access to approved PYQs
                if pyq.status != 'approved':
                    raise PermissionDenied("This PYQ is not approved for viewing")
        
        # Check if file exists
        if not pyq.paper_file or not os.path.exists(pyq.paper_file.path):
            raise Http404("File not found")
        
        # Determine if user wants to download or view inline
        download = request.GET.get('download', 'false').lower() == 'true'
        
        # Get file information
        file_path = pyq.paper_file.path
        file_name = os.path.basename(file_path)
        
        # Generate a descriptive filename for download
        descriptive_name = f"{pyq.subject.name}_{pyq.year}_Sem{pyq.semester}"
        if pyq.regulation:
            descriptive_name += f"_{pyq.regulation}"
        
        # Get file extension
        _, ext = os.path.splitext(file_name)
        descriptive_filename = f"{descriptive_name}{ext}"
        
        # Determine content type
        content_type, _ = mimetypes.guess_type(file_path)
        if not content_type:
            content_type = 'application/octet-stream'
        
        # Create response
        try:
            response = FileResponse(
                open(file_path, 'rb'),
                content_type=content_type,
                filename=descriptive_filename
            )
            
            if download:
                # Force download
                response['Content-Disposition'] = f'attachment; filename="{descriptive_filename}"'
            else:
                # View inline (for PDFs in browser)
                response['Content-Disposition'] = f'inline; filename="{descriptive_filename}"'
            
            return response
            
        except Exception as e:
            raise Http404("Error serving file")
            
    except PreviousYearQuestion.DoesNotExist:
        raise Http404("PYQ not found")
