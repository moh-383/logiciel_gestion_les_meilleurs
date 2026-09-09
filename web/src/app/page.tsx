"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000/api/v1";

type Site = { id: string; nom: string; adresse?: string };
type Stats = {
  effectif: number;
  montant_collecte: number;
  montant_attendu: number;
  taux_recouvrement: number;
  nb_en_retard: number;
  nb_partiel: number;
};

function formatFcfa(value: number) {
  return `${new Intl.NumberFormat("fr-FR").format(value)} F`;
}

export default function Home() {
  const [token, setToken] = useState<string | null>(() =>
    typeof window === "undefined" ? null : window.localStorage.getItem("access_token"),
  );
  const [telephone, setTelephone] = useState("");
  const [motDePasse, setMotDePasse] = useState("");
  const [sites, setSites] = useState<Site[]>([]);
  const [stats, setStats] = useState<Record<string, Stats>>({});
  const [siteSelectionne, setSiteSelectionne] = useState<string>("tous");
  const [chargement, setChargement] = useState(false);
  const [erreur, setErreur] = useState("");

  async function requete<T>(path: string, accessToken: string): Promise<T> {
    const response = await fetch(`${API_BASE_URL}${path}`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message ?? "La requête a échoué.");
    }
    return data as T;
  }

  const chargerDashboard = useCallback(async (accessToken: string) => {
    setChargement(true);
    setErreur("");
    try {
      const payload = await requete<{ data?: Site[] } | Site[]>(
        "/sites?limit=100",
        accessToken,
      );
      const liste = Array.isArray(payload) ? payload : payload.data ?? [];
      const resultats = await Promise.all(
        liste.map(async (site) => [
          site.id,
          await requete<Stats>(`/sites/${site.id}/stats/paiements`, accessToken),
        ] as const),
      );
      setSites(liste);
      setStats(Object.fromEntries(resultats));
    } catch (error) {
      setErreur(error instanceof Error ? error.message : "Impossible de charger le dashboard.");
    } finally {
      setChargement(false);
    }
  }, []);

  useEffect(() => {
    if (token) queueMicrotask(() => void chargerDashboard(token));
  }, [chargerDashboard, token]);

  async function connecter(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setChargement(true);
    setErreur("");
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ telephone, mot_de_passe: motDePasse }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message ?? "Connexion impossible.");
      window.localStorage.setItem("access_token", data.access_token);
      setToken(data.access_token);
    } catch (error) {
      setErreur(error instanceof Error ? error.message : "Connexion impossible.");
      setChargement(false);
    }
  }

  function deconnecter() {
    window.localStorage.removeItem("access_token");
    setToken(null);
    setSites([]);
    setStats({});
  }

  if (!token) {
    return (
      <main className="login-shell">
        <section className="login-panel">
          <img src="/logo-mark.png" alt="Les meilleurs" className="brand-mark" />
          <p className="eyebrow">Pilotage scolaire</p>
          <h1>Vue direction</h1>
          <p className="muted">Connecte-toi pour suivre les sites et le recouvrement.</p>
          <form onSubmit={connecter} className="login-form">
            <label>Téléphone<input value={telephone} onChange={(event) => setTelephone(event.target.value)} /></label>
            <label>Mot de passe<input type="password" value={motDePasse} onChange={(event) => setMotDePasse(event.target.value)} /></label>
            {erreur && <p className="error-message">{erreur}</p>}
            <button disabled={chargement} type="submit">{chargement ? "Connexion..." : "Ouvrir le dashboard"}</button>
          </form>
        </section>
      </main>
    );
  }

  const sitesVisibles = siteSelectionne === "tous"
    ? sites
    : sites.filter((site) => site.id === siteSelectionne);
  const statsVisibles = sitesVisibles.map((site) => stats[site.id]).filter(Boolean);
  const totalEffectif = statsVisibles.reduce((sum, item) => sum + item.effectif, 0);
  const totalCollecte = statsVisibles.reduce((sum, item) => sum + Number(item.montant_collecte), 0);
  const totalAttendu = statsVisibles.reduce((sum, item) => sum + Number(item.montant_attendu), 0);
  const tauxGlobal = totalAttendu ? totalCollecte / totalAttendu : 0;

  return (
    <main className="dashboard-shell">
      <header className="topbar">
          <div className="topbar-brand">
          <img src="/logo-mark.png" alt="Les meilleurs" className="topbar-logo" />
          <div><p className="eyebrow">Les meilleurs · direction</p><h1>Tableau de pilotage</h1></div>
          </div>
        <button className="button-quiet" onClick={deconnecter}>Déconnexion</button>
      </header>
      <section className="dashboard-content">
        <div className="toolbar"><div><p className="eyebrow">Vue multi-sites</p><h2>La rentrée, en chiffres</h2></div><select value={siteSelectionne} onChange={(event) => setSiteSelectionne(event.target.value)}><option value="tous">Tous les sites</option>{sites.map((site) => <option key={site.id} value={site.id}>{site.nom}</option>)}</select></div>
        {erreur && <p className="error-message">{erreur}</p>}
        {chargement ? <div className="loading">Chargement des indicateurs...</div> : <>
          <section className="metric-grid">
            <article className="metric-card accent"><span>Élèves suivis</span><strong>{totalEffectif}</strong><small>{sitesVisibles.length} site(s) visible(s)</small></article>
            <article className="metric-card"><span>Montant collecté</span><strong>{formatFcfa(totalCollecte)}</strong><small>sur {formatFcfa(totalAttendu)} attendus</small></article>
            <article className="metric-card"><span>Recouvrement global</span><strong>{Math.round(tauxGlobal * 100)}%</strong><small>objectif de suivi financier</small></article>
          </section>
          <section className="section-heading"><div><p className="eyebrow">Comparatif</p><h2>Performance des sites</h2></div><button className="button-quiet" onClick={() => token && chargerDashboard(token)}>Actualiser</button></section>
          <section className="site-table" aria-label="Performance des sites"><div className="table-head"><span>Site</span><span>Élèves</span><span>Collecté</span><span>Recouvrement</span><span>Alertes</span></div>{sitesVisibles.map((site) => { const item = stats[site.id]; if (!item) return null; return <div className="table-row" key={site.id}><strong>{site.nom}</strong><span>{item.effectif}</span><span>{formatFcfa(Number(item.montant_collecte))}</span><span><i className="progress"><b style={{ width: `${Math.min(item.taux_recouvrement * 100, 100)}%` }} /></i>{Math.round(item.taux_recouvrement * 100)}%</span><span className="alerts">{item.nb_en_retard + item.nb_partiel}</span></div>; })}</section>
        </>}
      </section>
    </main>
  );
}
