from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import ConnexionView, DeconnexionView

urlpatterns = [
    path("login", ConnexionView.as_view()),
    path("refresh", TokenRefreshView.as_view()),
    path("logout", DeconnexionView.as_view()),
]
