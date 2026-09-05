from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    ContactViewSet,
    ContactsEleveView,
    EcheancesEleveView,
    EleveSyncView,
    EleveViewSet,
)
router = DefaultRouter(trailing_slash=False)
router.register("eleves", EleveViewSet, basename="eleve")
router.register("contacts", ContactViewSet, basename="contact")
urlpatterns = [
    path("eleves/<uuid:pk>/contacts", ContactsEleveView.as_view()),
    path("sync/eleves", EleveSyncView.as_view()),
    path("eleves/<uuid:pk>/echeances", EcheancesEleveView.as_view()),
] + router.urls
