from django.urls import path

from .views import EchangeSyncView, EchangesEleveView, EchangesSiteView

urlpatterns = [
    path("eleves/<uuid:pk>/echanges", EchangesEleveView.as_view()),
    path("sites/<uuid:pk>/echanges", EchangesSiteView.as_view()),
    path("sync/echanges", EchangeSyncView.as_view()),
]