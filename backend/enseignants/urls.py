from django.urls import path

from .views import AffectationDetailView, AffectationsCreateView, CreneauDetailView, CreneauxView, EnseignantDetailView, EnseignantListView, MesAffectationsView, MesSeancesView, MonPlanningView, MonRapportMensuelView, RapportMensuelEnseignantView, SeanceCreateView

urlpatterns = [
    path("enseignants", EnseignantListView.as_view()),
    path("enseignants/<uuid:pk>", EnseignantDetailView.as_view()),
    path("enseignants/<uuid:pk>/affectations", AffectationsCreateView.as_view()),
    path("affectations/<uuid:pk>", AffectationDetailView.as_view()),
    path("affectations/<uuid:pk>/creneaux", CreneauxView.as_view()),
    path("creneaux/<uuid:pk>", CreneauDetailView.as_view()),
    path("mon-planning", MonPlanningView.as_view()),
    path("mes-affectations", MesAffectationsView.as_view()),
    path("mes-seances", MesSeancesView.as_view()),
    path("mon-rapport-mensuel", MonRapportMensuelView.as_view()),
    path("seances", SeanceCreateView.as_view()),
    path("enseignants/<uuid:pk>/rapport-mensuel", RapportMensuelEnseignantView.as_view()),
]
