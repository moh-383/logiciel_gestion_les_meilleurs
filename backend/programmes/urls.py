from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (GroupeDetailView, GroupesSessionView, InscriptionsView, InscriptionAnnulerView, InscriptionConfirmerView, InscriptionDetailView, ProgrammeViewSet, ResultatExamenDetailView, ResultatsExamenView, SeancesGroupeView, SessionProgrammeDetailView, SessionTransitionView, SessionsProgrammeView, StatistiquesExamenView, TableauBordProgrammeView, TarifViewSet)

router = DefaultRouter(trailing_slash=False)
router.register("programmes", ProgrammeViewSet, basename="programme")
router.register("tarifs-programmes", TarifViewSet, basename="tarif-programme")
urlpatterns = [
    path("programmes/<uuid:pk>/sessions", SessionsProgrammeView.as_view()),
    path("sessions-programmes/<uuid:pk>", SessionProgrammeDetailView.as_view()),
    path("sessions-programmes/<uuid:pk>/<str:action>", SessionTransitionView.as_view()),
    path("sessions-programmes/<uuid:pk>/groupes", GroupesSessionView.as_view()),
    path("sessions-programmes/<uuid:pk>/tableau-bord", TableauBordProgrammeView.as_view()),
    path("groupes-programmes/<uuid:pk>", GroupeDetailView.as_view()),
    path("groupes-programmes/<uuid:pk>/seances", SeancesGroupeView.as_view()),
    path("inscriptions-programmes", InscriptionsView.as_view()),
    path("inscriptions-programmes/<uuid:pk>", InscriptionDetailView.as_view()),
    path("inscriptions-programmes/<uuid:pk>/confirmer", InscriptionConfirmerView.as_view()),
    path("inscriptions-programmes/<uuid:pk>/annuler", InscriptionAnnulerView.as_view()),
    path("resultats-examens", ResultatsExamenView.as_view()),
    path("resultats-examens/<uuid:pk>", ResultatExamenDetailView.as_view()),
    path("programmes/<uuid:pk>/statistiques-examens", StatistiquesExamenView.as_view()),
] + router.urls
