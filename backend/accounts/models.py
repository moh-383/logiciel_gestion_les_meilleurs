import uuid

from django.contrib.auth.base_user import BaseUserManager
from django.contrib.auth.models import AbstractUser
from django.db import models


class UtilisateurManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, telephone, password=None, **extra_fields):
        if not telephone:
            raise ValueError("Le téléphone est obligatoire.")
        user = self.model(telephone=telephone, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, telephone, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)
        if not extra_fields.get("is_staff") or not extra_fields.get("is_superuser"):
            raise ValueError("Un superutilisateur doit être staff et superuser.")
        return self.create_user(telephone, password, **extra_fields)


class Utilisateur(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = None
    telephone = models.CharField(max_length=30, unique=True)
    nom = models.CharField(max_length=150)
    poste = models.ForeignKey("core.Poste", null=True, blank=True, on_delete=models.PROTECT, related_name="utilisateurs")
    site = models.ForeignKey("core.Site", null=True, blank=True, on_delete=models.PROTECT, related_name="utilisateurs")

    USERNAME_FIELD = "telephone"
    REQUIRED_FIELDS = ["nom"]
    objects = UtilisateurManager()

    @property
    def tous_sites(self):
        return bool(self.poste and self.poste.tous_sites)

    def a_permission(self, code):
        return bool(self.is_superuser or (self.poste and self.poste.permissions.filter(code=code).exists()))

    def __str__(self):
        return self.nom or self.telephone
