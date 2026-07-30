import os
import shutil
import subprocess
import sys
from pathlib import Path

from desktop_app.database import (
    create_project_document,
    delete_project_document,
    get_project_document,
    list_project_documents,
)


DOCUMENT_CATEGORIES = [
    "Contrato",
    "Fatura",
    "Proposta",
    "Projeto técnico",
    "Fotos",
    "Documentos pessoais",
    "Outros",
]


class ProjectDocuments:
    def __init__(self, storage_dir="project_documents"):
        self.storage_dir = self._resolve_storage_dir(storage_dir)
        self.storage_dir.mkdir(parents=True, exist_ok=True)

    def upload(self, project_id, source_path, category):
        source = Path(source_path)
        if not source.exists():
            raise FileNotFoundError(f"Arquivo não encontrado: {source}")
        if category not in DOCUMENT_CATEGORIES:
            category = "Outros"

        project_dir = self.storage_dir / f"project_{project_id}" / self._slug(category)
        project_dir.mkdir(parents=True, exist_ok=True)

        destination = self._unique_destination(project_dir, source.name)
        shutil.copy2(source, destination)

        document_id = create_project_document(
            project_id=project_id,
            category=category,
            original_name=source.name,
            stored_path=str(destination),
            file_size=destination.stat().st_size,
        )
        return self.get(document_id)

    def list(self, project_id, category=None):
        return [
            dict(row)
            for row in list_project_documents(project_id, category)
        ]

    def get(self, document_id):
        row = get_project_document(document_id)
        return dict(row) if row else None

    def delete(self, document_id):
        document = self.get(document_id)
        if not document:
            return False

        path = Path(document["stored_path"])
        if path.exists():
            path.unlink()

        delete_project_document(document_id)
        return True

    def open(self, document_id):
        document = self.get(document_id)
        if not document:
            raise FileNotFoundError("Documento não encontrado no banco.")

        path = Path(document["stored_path"])
        if not path.exists():
            raise FileNotFoundError(f"Arquivo não encontrado: {path}")

        if sys.platform.startswith("linux"):
            subprocess.Popen(["xdg-open", str(path)])
        elif sys.platform == "darwin":
            subprocess.Popen(["open", str(path)])
        elif os.name == "nt":
            os.startfile(str(path))
        return path

    def _resolve_storage_dir(self, storage_dir):
        if getattr(sys, "frozen", False):
            return Path(sys.executable).resolve().parent / storage_dir
        return Path(__file__).resolve().parents[1] / storage_dir

    def _unique_destination(self, directory, filename):
        stem = Path(filename).stem
        suffix = Path(filename).suffix
        destination = directory / filename
        counter = 1
        while destination.exists():
            destination = directory / f"{stem}_{counter}{suffix}"
            counter += 1
        return destination

    def _slug(self, value):
        text = str(value).lower()
        output = []
        for char in text:
            if char.isalnum():
                output.append(char)
            elif char in {" ", "-", "_"}:
                output.append("_")
        return "".join(output).strip("_") or "outros"
