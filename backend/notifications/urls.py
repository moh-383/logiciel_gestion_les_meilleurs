from django.urls import path

from .views import NotificationsListView

urlpatterns = [
    path("notifications", NotificationsListView.as_view()),
]