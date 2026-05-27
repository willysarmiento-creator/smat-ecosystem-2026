from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas, auth, database

models.Base.metadata.create_all(bind=database.engine)
app = FastAPI(title="SMAT API - Unidad I")

# CONFIGURACIÓN CRÍTICA PARA SEMANA 5 (CONEXIÓN MÓVIL)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/token", tags=["Seguridad"])
def login():
    return {"access_token": auth.crear_token({"sub": "admin_fisi"}), "token_type": "bearer"}

@app.get("/estaciones/")
def listar_estaciones(db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    estaciones = db.query(models.EstacionDB).all()
    
    resultado = []
    for est in estaciones:
        ultima_lectura = db.query(models.LecturaDB).filter(
            models.LecturaDB.estacion_id == est.id
        ).order_by(models.LecturaDB.id.desc()).first()
        
        datos_estacion = {
            "id": est.id,
            "nombre": est.nombre,
            "ubicacion": est.ubicacion,
            "ultima_lectura": ultima_lectura.valor if ultima_lectura else 0.0 
        }
        resultado.append(datos_estacion)
        
    return resultado

@app.post("/estaciones/", tags=["SMAT"])
def crear_estacion(estacion: schemas.EstacionCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    nueva = models.EstacionDB(**estacion.dict())
    db.add(nueva)
    db.commit()
    return nueva

@app.post("/lecturas/", tags=["Telemetría"])
def registrar_lectura(lectura: schemas.LecturaCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    # Reto Maestro: Validación de existencia
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    nueva_lectura = models.LecturaDB(**lectura.dict())
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura registrada con éxito"}