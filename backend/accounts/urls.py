from rest_framework.routers import DefaultRouter

from .views import UtilisateurViewSet

router = DefaultRouter(trailing_slash=False)
router.register("utilisateurs", UtilisateurViewSet, basename="utilisateur")
urlpatterns = router.urls
from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import MonTokenFcmView, UtilisateurViewSet

router = DefaultRouter(trailing_slash=False)
router.register("utilisateurs", UtilisateurViewSet, basename="utilisateur")
urlpatterns = [
    path("utilisateurs/me/fcm-token", MonTokenFcmView.as_view()),
] + router.urls
