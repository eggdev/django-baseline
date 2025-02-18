"""
An abstract model class that names a model
"""
from django.db import models


class NamedModel(models.Model):
    """
    Model that provides a name to a model
    """

    name = models.CharField(max_length=256)

    class Meta:
        abstract = True

    def __str__(self):
        return str(self.name)
