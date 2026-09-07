from rest_framework.routers import DefaultRouter

from .views import UtilisateurViewSet

router = DefaultRouter(trailing_slash=False)
router.register("utilisateurs", UtilisateurViewSet, basename="utilisateur")
urlpatterns = router.urls
