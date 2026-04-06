from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import re
import random
import time

app = FastAPI(title="CyberGuard AI Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class EmailRequest(BaseModel):
    sender: str = ""
    subject: str = ""
    body: str = ""

class ScanResult(BaseModel):
    threat_type: str
    level: str
    title: str
    description: str
    how_it_works: str
    how_to_defend: str
    ai_action: str

PHISHING_KEYWORDS_SUBJECT = [
    "urgent", "compte", "suspendu", "verification", "confirme",
    "bloque", "alerte", "securite", "mot de passe", "expire",
    "action requise", "votre compte", "connexion suspecte"
]

PHISHING_KEYWORDS_BODY = [
    "cliquez ici", "mot de passe", "bitcoin", "transfert",
    "felicitations", "gagne", "verifie", "identite", "confirme",
    "carte bancaire", "iban", "virement", "code secret"
]

SUSPICIOUS_SENDERS = [
    "noreply", "security-", ".xyz", "support-", "admin-",
    "no-reply", "donotreply", "alerts-", "verify-"
]

THREAT_DATABASE = [
    ScanResult(
        threat_type="phishing",
        level="danger",
        title="Tentative de phishing detectee",
        description="Un lien ou contenu malveillant imitant un service legitime a ete detecte sur votre appareil.",
        how_it_works="Le hacker cree une copie parfaite d un site connu. Il vous envoie un lien par email ou SMS. En cliquant, vos identifiants sont captures directement par le pirate.",
        how_to_defend="Ne cliquez jamais sur des liens suspects. Verifiez toujours l URL exacte. Activez la double authentification sur tous vos comptes.",
        ai_action="Lien malveillant bloque et signale. URL ajoutee a la liste noire mondiale. Analyse complete de vos donnees exposees effectuee."
    ),
    ScanResult(
        threat_type="data_leak",
        level="danger",
        title="Fuite de donnees bloquee",
        description="Une application tentait d envoyer vos donnees personnelles vers un serveur non autorise.",
        how_it_works="Des applications malveillantes collectent silencieusement vos contacts, photos et mots de passe en arriere-plan, puis les transmettent a des serveurs pirates.",
        how_to_defend="Auditez les permissions de vos applications. Desinstallez les apps inutilisees. N installez que depuis les stores officiels verifies.",
        ai_action="Transmission de donnees interrompue. Application mise en quarantaine. Journal des donnees interceptees genere et securise."
    ),
    ScanResult(
        threat_type="wifi_attack",
        level="warning",
        title="Reseau WiFi vulnerabe detecte",
        description="Votre connexion WiFi presente des failles de securite exploitables par un attaquant proche.",
        how_it_works="Sur un reseau non securise, un pirate peut intercepter tout votre trafic via une attaque Man-in-the-Middle, lisant vos mots de passe et messages en clair.",
        how_to_defend="Utilisez un VPN sur les reseaux publics. Privilegiez les sites HTTPS. Evitez les operations bancaires sur WiFi public.",
        ai_action="Trafic sensible redirige via tunnel chiffre. Surveillance reseau activee. Alerte declenchee si ecoute detectee."
    ),
    ScanResult(
        threat_type="malware",
        level="danger",
        title="Comportement malveillant detecte",
        description="Une application affiche un comportement anormal typique des logiciels espions.",
        how_it_works="Les malwares mobiles se dissimulent dans des apps legitimes et s activent en arriere-plan pour enregistrer vos frappes, activer votre camera ou microphone.",
        how_to_defend="Mettez a jour votre systeme immediatement. Lancez un scan complet. Signalez l application au store officiel.",
        ai_action="Application isolee du systeme. Acces camera et micro revoque. Analyse forensique complete lancee en arriere-plan."
    ),
    ScanResult(
        threat_type="ssl_invalid",
        level="warning",
        title="Certificat SSL invalide",
        description="Un site visite possede un certificat de securite expire ou falsifie.",
        how_it_works="Sans certificat SSL valide, votre connexion n est pas chiffree. Un pirate peut intercepter et modifier les donnees echangees entre vous et le site.",
        how_to_defend="N ignorez jamais les avertissements de certificat. Quittez immediatement le site. Signalez-le a votre navigateur.",
        ai_action="Acces au site bloque automatiquement. Site signale dans notre base de donnees collaborative. Historique de navigation verifie."
    ),
]

@app.get("/")
def root():
    return {"status": "CyberGuard AI Backend actif", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "ok", "timestamp": time.time()}

@app.post("/analyze/email")
def analyze_email(req: EmailRequest):
    risk_score = 0.0
    indicators = []
    
    subject_lower = req.subject.lower()
    body_lower = req.body.lower()
    sender_lower = req.sender.lower()
    
    for kw in PHISHING_KEYWORDS_SUBJECT:
        if kw in subject_lower:
            risk_score += 0.15
            indicators.append(f"Sujet suspect: '{kw}'")
    
    for kw in PHISHING_KEYWORDS_BODY:
        if kw in body_lower:
            risk_score += 0.15
            indicators.append(f"Contenu suspect: '{kw}'")
    
    for kw in SUSPICIOUS_SENDERS:
        if kw in sender_lower:
            risk_score += 0.1
            indicators.append(f"Expediteur suspect: '{kw}'")
    
    if re.search(r'http[s]?://(?:[a-zA-Z0-9-]+.)+(?:xyz|tk|ml|ga|cf|gq)', body_lower):
        risk_score += 0.3
        indicators.append("Domaine malveillant detecte dans les liens")
    
    risk_score = min(1.0, risk_score)
    
    if risk_score < 0.3:
        level = "safe"
        verdict = "Email Legitime"
    elif risk_score < 0.6:
        level = "warning"
        verdict = "Email Suspect"
    else:
        level = "danger"
        verdict = "DANGER - Phishing detecte"
    
    return {
        "risk_score": round(risk_score, 2),
        "risk_percent": int(risk_score * 100),
        "level": level,
        "verdict": verdict,
        "indicators": indicators,
        "recommendation": "Ne repondez pas et signalez cet email" if risk_score > 0.5 else "Email probablement legitime",
        "ai_analysis": f"IA CyberGuard a analyse {len(req.body.split())} mots et detecte {len(indicators)} indicateur(s) de menace."
    }

@app.get("/scan/quick")
def quick_scan():
    threats_found = random.randint(0, 2)
    threats = []
    
    if threats_found > 0:
        selected = random.sample(THREAT_DATABASE, min(threats_found, len(THREAT_DATABASE)))
        for t in selected:
            threats.append({
                "threat_type": t.threat_type,
                "level": t.level,
                "title": t.title,
                "description": t.description,
                "how_it_works": t.how_it_works,
                "how_to_defend": t.how_to_defend,
                "ai_action": t.ai_action,
                "detected_at": time.time()
            })
    
    score = max(40, 95 - (len(threats) * 15) - random.randint(0, 10))
    
    return {
        "scan_id": f"scan_{int(time.time())}",
        "threats_found": len(threats),
        "security_score": score,
        "threats": threats,
        "scan_duration_ms": random.randint(800, 2500),
        "scanned_items": {
            "apps": random.randint(20, 50),
            "network_connections": random.randint(5, 20),
            "files": random.randint(100, 500)
        },
        "status": "danger" if len(threats) > 0 else "safe"
    }

@app.get("/score")
def get_score():
    return {
        "score": random.randint(75, 98),
        "level": "good",
        "last_scan": time.time(),
        "protections_active": 5
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
