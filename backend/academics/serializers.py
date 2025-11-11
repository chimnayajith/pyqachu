from rest_framework import serializers
from django.contrib.auth.models import User
from .models import College, Branch, Subject, PreviousYearQuestion, UserRole
from .permissions import RoleBasedPermissionMixin


class UserRoleSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    college_name = serializers.CharField(source='college.name', read_only=True)
    assigned_by_username = serializers.CharField(source='assigned_by.username', read_only=True)
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    
    class Meta:
        model = UserRole
        fields = [
            'id', 'user', 'username', 'email', 'college', 'college_name', 
            'role', 'role_display', 'is_active', 'assigned_by', 
            'assigned_by_username', 'created_at', 'updated_at'
        ]


class CollegeSerializer(serializers.ModelSerializer):
    admin_count = serializers.SerializerMethodField()
    moderator_count = serializers.SerializerMethodField()
    user_role = serializers.SerializerMethodField()
    
    class Meta:
        model = College
        fields = ['id', 'name', 'location', 'is_active', 'created_at', 'admin_count', 'moderator_count', 'user_role']
    
    def get_admin_count(self, obj):
        return obj.user_roles.filter(role='admin', is_active=True).count()
    
    def get_moderator_count(self, obj):
        return obj.user_roles.filter(role='moderator', is_active=True).count()
    
    def get_user_role(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return RoleBasedPermissionMixin.get_user_role(request.user, obj)
        return None


class BranchSerializer(serializers.ModelSerializer):
    college_name = serializers.CharField(source='college.name', read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Branch
        fields = ['id', 'name', 'code', 'college', 'college_name', 'is_active', 
                 'created_by', 'created_by_username', 'created_at']


class SubjectSerializer(serializers.ModelSerializer):
    branch_name = serializers.CharField(source='branch.name', read_only=True)
    college_name = serializers.CharField(source='branch.college.name', read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Subject
        fields = ['id', 'name', 'code', 'branch', 'branch_name', 'college_name', 
                 'is_active', 'created_by', 'created_by_username', 'created_at']


class PreviousYearQuestionSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    branch_name = serializers.CharField(source='subject.branch.name', read_only=True)
    college_name = serializers.CharField(source='subject.branch.college.name', read_only=True)
    uploaded_by_username = serializers.CharField(source='uploaded_by.username', read_only=True)
    reviewed_by_username = serializers.CharField(source='reviewed_by.username', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = PreviousYearQuestion
        fields = [
            'id', 'year', 'semester', 'regulation', 'paper_file', 
            'uploaded_by', 'uploaded_by_username', 'status', 'status_display',
            'reviewed_by', 'reviewed_by_username', 'review_notes',
            'uploaded_at', 'reviewed_at', 'subject', 'subject_name', 
            'branch_name', 'college_name'
        ]


class PYQUploadSerializer(serializers.ModelSerializer):
    """Serializer for uploading new PYQs"""
    class Meta:
        model = PreviousYearQuestion
        fields = ['subject', 'year', 'semester', 'regulation', 'paper_file']
    
    def create(self, validated_data):
        validated_data['uploaded_by'] = self.context['request'].user
        return super().create(validated_data)


class PYQModerationSerializer(serializers.ModelSerializer):
    """Serializer for moderating PYQs"""
    class Meta:
        model = PreviousYearQuestion
        fields = ['status', 'review_notes']
    
    def update(self, instance, validated_data):
        if 'status' in validated_data:
            instance.reviewed_by = self.context['request'].user
            from django.utils import timezone
            instance.reviewed_at = timezone.now()
        return super().update(instance, validated_data)