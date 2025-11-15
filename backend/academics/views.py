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
from .models import College, Branch, Subject, PreviousYearQuestion, UserRole, Bookmark
from .serializers import (
    CollegeSerializer, BranchSerializer, SubjectSerializer, 
    PreviousYearQuestionSerializer, UserRoleSerializer,
    PYQUploadSerializer, PYQModerationSerializer, BookmarkSerializer
)
from .permissions import RoleBasedPermissionMixin


class CollegeListView(generics.ListAPIView):
    """
    GET /api/colleges/ - List colleges accessible to the user
    """
    serializer_class = CollegeSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'location']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return College.objects.filter(is_active=True)
        
        # Return colleges where user has any role
        user_colleges = RoleBasedPermissionMixin.get_user_colleges(user)
        return user_colleges


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
        
        if (college_id):
            queryset = queryset.filter(college_id=college_id)
            # Check if user has access to this college
            user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
            if not user_colleges.filter(id=college_id).exists():
                return Branch.objects.none()
        else:
            # Filter to only colleges user has access to
            user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
            queryset = queryset.filter(college__in=user_colleges)
        
        return queryset


class SubjectListView(generics.ListAPIView):
    """
    GET /api/subjects/?branch_id= - Get subjects for a specific branch
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
        
        if branch_id:
            queryset = queryset.filter(branch_id=branch_id)
            # Check if user has access to this branch's college
            try:
                branch = Branch.objects.select_related('college').get(id=branch_id)
                user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
                if not user_colleges.filter(id=branch.college.id).exists():
                    return Subject.objects.none()
            except Branch.DoesNotExist:
                return Subject.objects.none()
        else:
            # Filter to only colleges user has access to
            user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
            queryset = queryset.filter(branch__college__in=user_colleges)
        
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
        
        # Filter by user's accessible colleges
        user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
        queryset = queryset.filter(subject__branch__college__in=user_colleges)
        
        # Only show approved PYQs unless user can moderate
        if not self.request.user.is_superuser:
            # Check if user can moderate for any college
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
    POST /api/pyqs/upload/ - Upload a new PYQ
    """
    serializer_class = PYQUploadSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        # Verify user has access to the subject's college
        subject = serializer.validated_data['subject']
        user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
        
        if not user_colleges.filter(id=subject.branch.college.id).exists():
            raise PermissionDenied("You don't have access to upload PYQs for this college")
        
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


class PendingPYQListView(generics.ListAPIView):
    """
    GET /api/pyqs/pending/ - Get pending PYQs for moderation
    """
    serializer_class = PreviousYearQuestionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['subject__name', 'uploaded_by__username', 'regulation']
    ordering_fields = ['uploaded_at', 'year', 'semester']
    ordering = ['-uploaded_at']  # Most recent first

    def get_queryset(self):
        # Only allow moderators and superusers to access pending PYQs
        user = self.request.user
        
        if user.is_superuser:
            # Superusers can see all pending PYQs
            return PreviousYearQuestion.objects.filter(status='pending').select_related(
                'subject', 'subject__branch', 'subject__branch__college', 'uploaded_by', 'reviewed_by'
            )
        
        # Get colleges where user has moderation permissions
        user_colleges = RoleBasedPermissionMixin.get_user_colleges(user)
        accessible_colleges = []
        
        for college in user_colleges:
            if RoleBasedPermissionMixin.can_moderate_pyqs(user, college):
                accessible_colleges.append(college)
        
        if not accessible_colleges:
            return PreviousYearQuestion.objects.none()
        
        # Return pending PYQs from accessible colleges
        return PreviousYearQuestion.objects.filter(
            status='pending',
            subject__branch__college__in=accessible_colleges
        ).select_related(
            'subject', 'subject__branch', 'subject__branch__college', 'uploaded_by', 'reviewed_by'
        )


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_pyq_details(request, pk):
    """
    PATCH /api/pyqs/<id>/update-details/ - Update PYQ details (year, semester, regulation) during moderation
    """
    try:
        pyq = get_object_or_404(PreviousYearQuestion, pk=pk)
        college = pyq.subject.branch.college
        
        # Check if user can moderate for this college
        if not RoleBasedPermissionMixin.can_moderate_pyqs(request.user, college):
            raise PermissionDenied("You don't have permission to moderate PYQs for this college")
        
        # Extract the fields that can be updated
        year = request.data.get('year')
        semester = request.data.get('semester') 
        regulation = request.data.get('regulation')
        
        # Update the fields if provided
        if year is not None:
            pyq.year = year
        if semester is not None:
            pyq.semester = semester
        if regulation is not None:
            pyq.regulation = regulation
            
        pyq.save()
        
        serializer = PreviousYearQuestionSerializer(pyq)
        return Response(serializer.data)
        
    except PreviousYearQuestion.DoesNotExist:
        raise Http404("PYQ not found")


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def moderate_pyq(request, pk):
    """
    POST /api/pyqs/<id>/moderate/ - Approve or reject a PYQ
    """
    try:
        pyq = get_object_or_404(PreviousYearQuestion, pk=pk)
        college = pyq.subject.branch.college
        
        # Check if user can moderate for this college
        if not RoleBasedPermissionMixin.can_moderate_pyqs(request.user, college):
            raise PermissionDenied("You don't have permission to moderate PYQs for this college")
        
        action = request.data.get('action')  # 'approve' or 'reject'
        notes = request.data.get('notes', '')
        
        if action not in ['approve', 'reject']:
            return Response({'error': 'Action must be either "approve" or "reject"'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Update PYQ status
        pyq.status = 'approved' if action == 'approve' else 'rejected'
        pyq.reviewed_by = request.user
        pyq.reviewed_at = timezone.now()
        pyq.review_notes = notes
        pyq.save()
        
        serializer = PreviousYearQuestionSerializer(pyq)
        return Response({
            'message': f'PYQ {action}d successfully',
            'pyq': serializer.data
        })
        
    except PreviousYearQuestion.DoesNotExist:
        raise Http404("PYQ not found")


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
        
        # Check if user has access to this PYQ's college
        user_colleges = RoleBasedPermissionMixin.get_user_colleges(request.user)
        college = pyq.subject.branch.college
        
        if not user_colleges.filter(id=college.id).exists():
            raise PermissionDenied("You don't have access to this PYQ")
        
        # Only allow access to approved PYQs unless user can moderate
        if pyq.status != 'approved' and not request.user.is_superuser:
            if not RoleBasedPermissionMixin.can_moderate_pyqs(request.user, college):
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


class BookmarkListView(generics.ListAPIView):
    """
    GET /api/bookmarks/ - List user's bookmarks
    """
    serializer_class = BookmarkSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering = ['-created_at']

    def get_queryset(self):
        return Bookmark.objects.filter(
            user=self.request.user,
            pyq__status='approved'  # Only show bookmarks for approved PYQs
        ).select_related('pyq', 'pyq__subject', 'pyq__subject__branch', 'pyq__subject__branch__college')


class BookmarkCreateView(generics.CreateAPIView):
    """
    POST /api/bookmarks/ - Add a bookmark
    Body: {"pyq": <pyq_id>}
    """
    serializer_class = BookmarkSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        pyq = serializer.validated_data['pyq']
        
        # Check if user has access to this PYQ's college
        user_colleges = RoleBasedPermissionMixin.get_user_colleges(self.request.user)
        college = pyq.subject.branch.college
        
        if not user_colleges.filter(id=college.id).exists():
            raise PermissionDenied("You don't have access to this PYQ")
        
        # Only allow bookmarking approved PYQs (unless user can moderate)
        if pyq.status != 'approved' and not self.request.user.is_superuser:
            if not RoleBasedPermissionMixin.can_moderate_pyqs(self.request.user, college):
                raise PermissionDenied("Can only bookmark approved PYQs")
        
        try:
            serializer.save(user=self.request.user)
        except Exception as e:
            # Handle unique constraint violation (bookmark already exists)
            if 'UNIQUE constraint failed' in str(e):
                return Response(
                    {'error': 'PYQ is already bookmarked'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            raise


@api_view(['POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def bookmark_toggle(request, pyq_id):
    """
    POST /api/pyqs/<pyq_id>/bookmark/ - Add a PYQ to bookmarks
    DELETE /api/pyqs/<pyq_id>/bookmark/ - Remove a PYQ from bookmarks
    """
    try:
        pyq = get_object_or_404(PreviousYearQuestion, pk=pyq_id)
        
        # Check if user has access to this PYQ's college
        user_colleges = RoleBasedPermissionMixin.get_user_colleges(request.user)
        college = pyq.subject.branch.college
        
        if not user_colleges.filter(id=college.id).exists():
            raise PermissionDenied("You don't have access to this PYQ")
        
        # Only allow bookmarking approved PYQs unless user can moderate
        if pyq.status != 'approved' and not request.user.is_superuser:
            if not RoleBasedPermissionMixin.can_moderate_pyqs(request.user, college):
                raise PermissionDenied("This PYQ is not approved for bookmarking")
        
        if request.method == 'POST':
            # Add bookmark
            bookmark, created = Bookmark.objects.get_or_create(
                user=request.user,
                pyq=pyq
            )
            
            if created:
                serializer = BookmarkSerializer(bookmark)
                return Response({
                    'message': 'PYQ bookmarked successfully',
                    'bookmark': serializer.data
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    'message': 'PYQ is already bookmarked'
                }, status=status.HTTP_200_OK)
        
        elif request.method == 'DELETE':
            # Remove bookmark
            bookmark = Bookmark.objects.filter(user=request.user, pyq=pyq).first()
            
            if bookmark:
                bookmark.delete()
                return Response({
                    'message': 'Bookmark removed successfully'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'message': 'PYQ is not bookmarked'
                }, status=status.HTTP_404_NOT_FOUND)
            
    except PreviousYearQuestion.DoesNotExist:
        raise Http404("PYQ not found")


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_bookmark_status(request, pyq_id):
    """
    GET /api/pyqs/<pyq_id>/bookmark-status/ - Check if a PYQ is bookmarked by the user
    """
    try:
        pyq = get_object_or_404(PreviousYearQuestion, pk=pyq_id)
        is_bookmarked = Bookmark.objects.filter(user=request.user, pyq=pyq).exists()
        
        return Response({
            'is_bookmarked': is_bookmarked
        })
            
    except PreviousYearQuestion.DoesNotExist:
        raise Http404("PYQ not found")
