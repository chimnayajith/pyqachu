from django.contrib import admin
from django.utils import timezone
from django.contrib.auth.models import User
from .models import College, Branch, Subject, PreviousYearQuestion, UserRole
from .permissions import RoleBasedPermissionMixin


@admin.register(College)
class CollegeAdmin(admin.ModelAdmin):
    list_display = ['name', 'location', 'is_active', 'created_at', 'get_admin_count']
    search_fields = ['name', 'location']
    list_filter = ['is_active', 'created_at']
    ordering = ['name']
    actions = ['activate_colleges', 'deactivate_colleges']

    def get_admin_count(self, obj):
        return obj.user_roles.filter(role='admin', is_active=True).count()
    get_admin_count.short_description = 'Active Admins'

    def activate_colleges(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} colleges were activated.')
    activate_colleges.short_description = "Activate selected colleges"

    def deactivate_colleges(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} colleges were deactivated.')
    deactivate_colleges.short_description = "Deactivate selected colleges"


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
    list_display = ['user', 'get_user_email', 'role', 'college', 'is_active', 'assigned_by', 'created_at']
    search_fields = ['user__username', 'user__email', 'college__name']
    list_filter = ['role', 'is_active', 'college', 'created_at']
    ordering = ['college', 'role', 'user']
    actions = ['activate_roles', 'deactivate_roles']

    def get_user_email(self, obj):
        return obj.user.email
    get_user_email.short_description = 'Email'

    def save_model(self, request, obj, form, change):
        if not change:  # If creating new role
            obj.assigned_by = request.user
        super().save_model(request, obj, form, change)

    def activate_roles(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} user roles were activated.')
    activate_roles.short_description = "Activate selected roles"

    def deactivate_roles(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} user roles were deactivated.')
    deactivate_roles.short_description = "Deactivate selected roles"


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'college', 'is_active', 'created_by', 'created_at']
    search_fields = ['name', 'code', 'college__name']
    list_filter = ['college', 'is_active', 'created_at']
    ordering = ['college', 'name']
    actions = ['activate_branches', 'deactivate_branches']

    def save_model(self, request, obj, form, change):
        if not change:  # If creating new branch
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    def activate_branches(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} branches were activated.')
    activate_branches.short_description = "Activate selected branches"

    def deactivate_branches(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} branches were deactivated.')
    deactivate_branches.short_description = "Deactivate selected branches"


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'branch', 'get_college', 'is_active', 'created_by', 'created_at']
    search_fields = ['name', 'code', 'branch__name', 'branch__college__name']
    list_filter = ['branch__college', 'branch', 'is_active', 'created_at']
    ordering = ['branch', 'name']
    actions = ['activate_subjects', 'deactivate_subjects']

    def get_college(self, obj):
        return obj.branch.college.name
    get_college.short_description = 'College'

    def save_model(self, request, obj, form, change):
        if not change:  # If creating new subject
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    def activate_subjects(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} subjects were activated.')
    activate_subjects.short_description = "Activate selected subjects"

    def deactivate_subjects(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} subjects were deactivated.')
    deactivate_subjects.short_description = "Deactivate selected subjects"


@admin.register(PreviousYearQuestion)
class PreviousYearQuestionAdmin(admin.ModelAdmin):
    list_display = ['subject', 'year', 'semester', 'regulation', 'uploaded_by', 'status', 'reviewed_by', 'uploaded_at']
    search_fields = ['subject__name', 'year', 'regulation', 'uploaded_by__username']
    list_filter = ['status', 'year', 'semester', 'subject__branch__college', 'uploaded_at']
    ordering = ['-uploaded_at']
    actions = ['approve_pyqs', 'reject_pyqs', 'reset_to_pending']
    readonly_fields = ['uploaded_at', 'reviewed_at']

    def approve_pyqs(self, request, queryset):
        updated = queryset.update(
            status='approved',
            reviewed_by=request.user,
            reviewed_at=timezone.now()
        )
        self.message_user(request, f'{updated} PYQs were approved.')
    approve_pyqs.short_description = "Approve selected PYQs"

    def reject_pyqs(self, request, queryset):
        updated = queryset.update(
            status='rejected',
            reviewed_by=request.user,
            reviewed_at=timezone.now()
        )
        self.message_user(request, f'{updated} PYQs were rejected.')
    reject_pyqs.short_description = "Reject selected PYQs"

    def reset_to_pending(self, request, queryset):
        updated = queryset.update(
            status='pending',
            reviewed_by=None,
            reviewed_at=None,
            review_notes=''
        )
        self.message_user(request, f'{updated} PYQs were reset to pending.')
    reset_to_pending.short_description = "Reset to pending review"
