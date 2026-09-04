from django.urls import path

from .views import (DemandeAnnulationView, DemandeValidationDetailView, DemandesValidationView,
                    PaiementCreateView, PaiementsEleveView, PaiementsSiteView, PaiementsSyncView,
                    StatsPaiementsSiteView)

urlpatterns = [
    path("paiements", PaiementCreateView.as_view()),
    path("sync/paiements", PaiementsSyncView.as_view()),
    path("paiements/<uuid:pk>/demande-annulation", DemandeAnnulationView.as_view()),
    path("eleves/<uuid:pk>/paiements", PaiementsEleveView.as_view()),
    path("sites/<uuid:pk>/paiements", PaiementsSiteView.as_view()),
    path("sites/<uuid:pk>/stats/paiements", StatsPaiementsSiteView.as_view()),
    path("demandes-validation", DemandesValidationView.as_view()),
    path("demandes-validation/<uuid:pk>", DemandeValidationDetailView.as_view()),
]
