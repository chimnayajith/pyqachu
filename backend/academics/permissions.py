from django.contrib.auth.models import User
from .models import UserRole, College


class RoleBasedPermissionMixin:
    """Mixin to handle role-based permissions"""
    
    @staticmethod
    def get_user_role(user, college=None):
        """Get the user's highest role for a specific college or globally"""
        if not user.is_authenticated:
            return None
            
        # Check for Django superuser first
        if user.is_superuser:
            return 'superuser'
        
        if college:
            # Get highest role for specific college
            roles = UserRole.objects.filter(
                user=user, college=college, is_active=True
            ).values_list('role', flat=True)
            
            role_hierarchy = ['admin', 'moderator', 'student']
            for role in role_hierarchy:
                if role in roles:
                    return role
        
        return 'student'  # Default role
    
    @staticmethod
    def can_manage_college(user, college):
        """Check if user can manage a specific college"""
        role = RoleBasedPermissionMixin.get_user_role(user, college)
        return user.is_superuser or role == 'admin'
    
    @staticmethod
    def can_moderate_pyqs(user, college):
        """Check if user can moderate PYQs for a college"""
        role = RoleBasedPermissionMixin.get_user_role(user, college)
        return user.is_superuser or role in ['admin', 'moderator']
    
    @staticmethod
    def can_assign_roles(user, college, target_role):
        """Check if user can assign a specific role"""
        # Django superuser can assign any role
        if user.is_superuser:
            return True
            
        user_role = RoleBasedPermissionMixin.get_user_role(user, college)
        
        # College admin can assign moderator and student roles
        if user_role == 'admin' and target_role in ['moderator', 'student']:
            return True
        
        return False
    
    @staticmethod
    def get_user_colleges(user):
        """Get colleges that user has access to"""
        if user.is_superuser:
            return College.objects.filter(is_active=True)
        
        college_ids = UserRole.objects.filter(
            user=user, is_active=True
        ).values_list('college_id', flat=True)
        
        return College.objects.filter(id__in=college_ids, is_active=True)