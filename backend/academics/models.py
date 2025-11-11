from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError


class College(models.Model):
    """Model representing a college/university"""
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    class Meta:
        ordering = ['name']


class UserRole(models.Model):
    """Model for managing user roles across colleges"""
    ROLE_CHOICES = [
        ('admin', 'College Admin'),     # College administrators
        ('moderator', 'Moderator'),     # PYQ moderators
        ('student', 'Student'),         # Regular students
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='roles')
    college = models.ForeignKey(College, on_delete=models.CASCADE, related_name='user_roles')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active = models.BooleanField(default=True)
    assigned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_roles')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} - {self.get_role_display()} ({self.college.name})"

    class Meta:
        unique_together = ['user', 'college', 'role']
        ordering = ['college', 'role', 'user']


class Branch(models.Model):
    """Model representing a branch/department in a college"""
    college = models.ForeignKey(College, on_delete=models.CASCADE, related_name='branches')
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50, blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.college.name}"

    class Meta:
        ordering = ['college', 'name']
        unique_together = ['college', 'name']


class Subject(models.Model):
    """Model representing a subject in a branch"""
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name='subjects')
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50, blank=True, null=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.branch.name}"

    class Meta:
        ordering = ['branch', 'name']
        unique_together = ['branch', 'name']


class PreviousYearQuestion(models.Model):
    """Model representing a Previous Year Question (PYQ)"""
    STATUS_CHOICES = [
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE, related_name='pyqs')
    year = models.IntegerField()
    semester = models.IntegerField()
    regulation = models.CharField(max_length=100, blank=True, null=True)
    paper_file = models.FileField(upload_to='pyq_papers/')
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='uploaded_pyqs')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_pyqs')
    review_notes = models.TextField(blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.subject.name} - {self.year} (Sem {self.semester})"

    class Meta:
        ordering = ['-year', 'semester', 'subject']
        unique_together = ['subject', 'year', 'semester', 'regulation']

    @property
    def approved(self):
        """Backward compatibility property"""
        return self.status == 'approved'
