from django.urls import path
from .views import (
    CollegeListView, BranchListView, SubjectListView, 
    PreviousYearQuestionListView, PYQUploadView, PYQModerationView,
    user_role_info, UserRoleListView, pyq_download
)

urlpatterns = [
    # Original endpoints
    path('colleges/', CollegeListView.as_view(), name='college-list'),
    path('branches/', BranchListView.as_view(), name='branch-list'),
    path('subjects/', SubjectListView.as_view(), name='subject-list'),
    path('pyqs/', PreviousYearQuestionListView.as_view(), name='pyq-list'),
    
    # PYQ management endpoints
    path('pyqs/upload/', PYQUploadView.as_view(), name='pyq-upload'),
    path('pyqs/<int:pk>/download/', pyq_download, name='pyq-download'),
    path('pyqs/<int:pk>/moderate/', PYQModerationView.as_view(), name='pyq-moderate'),
    
    # User role endpoints
    path('user-role-info/', user_role_info, name='user-role-info'),
    path('user-roles/', UserRoleListView.as_view(), name='user-role-list'),
]