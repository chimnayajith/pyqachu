from django.urls import path
from .views import (
    CollegeListView, BranchListView, SubjectListView, 
    PreviousYearQuestionListView, PYQUploadView, PYQModerationView,
    PendingPYQListView, update_pyq_details, moderate_pyq,
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
    path('pyqs/pending/', PendingPYQListView.as_view(), name='pending-pyq-list'),
    path('pyqs/<int:pk>/download/', pyq_download, name='pyq-download'),
    path('pyqs/<int:pk>/moderate/', PYQModerationView.as_view(), name='pyq-moderate'),
    path('pyqs/<int:pk>/update-details/', update_pyq_details, name='update-pyq-details'),
    path('pyqs/<int:pk>/moderate-action/', moderate_pyq, name='moderate-pyq'),
    
    # User role endpoints
    path('user-role-info/', user_role_info, name='user-role-info'),
    path('user-roles/', UserRoleListView.as_view(), name='user-role-list'),
]