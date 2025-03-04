from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class Player(BaseModel):
    name: str
    elo: int
    id: UUID = Field(default_factory=uuid4)
    ...

    def __hash__(self):
        return hash(self.id)

    def __str__(self):
        return f"{self.name:15s} ({self.elo})"
