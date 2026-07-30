from dataclasses import dataclass


@dataclass
class AppUser:
    matricula: str
    nome: str
    email: str = ""
    cargo: str = ""
    permissao: str = "usuario"


class SyncError(Exception):
    pass
