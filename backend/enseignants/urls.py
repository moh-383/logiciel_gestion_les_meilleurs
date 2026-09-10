from django.urls import path

from .views import (
    CreneauDetailView,
    CreneauxView,
    MonPlanningView,
    RapportMensuelEnseignantView,
    SeanceCreateView,
)

urlpatterns = [
    path("affectations/<uuid:pk>/creneaux", CreneauxView.as_view()),
    path("creneaux/<uuid:pk>", CreneauDetailView.as_view()),
    path("mon-planning", MonPlanningView.as_view()),
    path("seances", SeanceCreateView.as_view()),
    path("enseignants/<uuid:pk>/rapport-mensuel", RapportMensuelEnseignantView.as_view()),
]