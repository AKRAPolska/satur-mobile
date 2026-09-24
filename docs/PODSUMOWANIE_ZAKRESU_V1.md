# Satur — podsumowanie zakresu v1 (źródło prawdy)

**Data:** 22 września 2026  
**Cel dokumentu:** trwały punkt odniesienia przy budowie aplikacji Flutter.  
**Hierarchia źródeł:**

1. **`docs/Wycena_Satur_Flutter.pdf`** — **nadrzędna** (zakres, auth, moduły, out-of-scope).
2. **`docs/stitch_myriad_pro_design_system/`** — wygląd, layout, komponenty UI; mockupy mogą zawierać **starszą / szerszą** wersję produktu — wtedy **nie rozszerzają zakresu**.

Jeśli design i wycena się rozjeżdżają → **wygrywa wycena**. Design używamy tylko do ekranów i detali wizualnych mieszczących się w v1.

---

## 1. Czym jest projekt

- Aplikacja mobilna **Satur** (sklep e-commerce / platforma benefitów zakupowych) dla klienta końcowego.
- Technologia: **Flutter**, **Android i iOS**.
- Backend + API **już gotowe** — prace wyłącznie: warstwa mobilna + integracja z API (bez serwera).
- Priorytet: najpierw **w pełni działający Android**, potem adaptacja i wydanie **iOS**.

---

## 2. Zakres wersji pierwszej (v1)

Ścieżka klienta indywidualnego:

1. Zgłoszenie chęci dołączenia do programu  
2. Logowanie **bez hasła** (kod dostępu na e-mail)  
3. Przeglądanie katalogu produktów  
4. Ulubione  
5. Koszyk  
6. Pełny checkout + płatność  

**v1 nie zawiera:** ustawień konta użytkownika ani konta firmowego B2B.

### 2.1. Poza zakresem v1 (jawnie z wyceny)

- Ustawienia konta (edycja profilu, zmiana danych)
- Konto firmowe B2B (pulpit, dane firmy, uprawnienia)
- Pełne centrum powiadomień — w v1 **tylko ikona** w pasku górnym, **bez** funkcjonalnej listy
- Panel administracyjny / CMS

Ekrany designu z tych obszarów **nie implementujemy w v1** (patrz §6).

---

## 3. Wycena czasowa (moduly)

Źródło: wycena z 9 września 2026. **Łącznie 277 h ≈ 35 dni** (1 osoba × 8 h).

| # | Moduł | Godziny |
|---|--------|---------|
| 1 | Fundamenty + Design System + API client | 36 |
| 2 | Rejestracja do programu + logowanie bez hasła | 25 |
| 3 | Przeglądanie oferty | 56 |
| 4 | Lista ulubionych | 9 |
| 5 | Koszyk | 12 |
| 6 | Checkout (4 kroki + potwierdzenie) | 59 |
| 7 | Nawigacja i routing | 8 |
| 8 | Testy + wydanie Android (Play) | 18 |
| 9 | Adaptacja + wydanie iOS (App Store) | 30 |
| 10 | Testy końcowe i stabilizacja | 24 |
| | **Razem** | **277** |

### Szczegóły modułów (skrót)

**1. Fundamenty (36 h)**  
Projekt Flutter (dev/prod), tokeny DS, biblioteka komponentów (przyciski, formularze, karty, oceny, etykiety), HTTP + tokeny sesji + błędy sieci.

**2. Auth / program (25 h)**  
Ekran startowy (Zaloguj / Dołącz do programu); formularz zgłoszenia + potwierdzenie e-mail; logowanie: e-mail/login → kod → błędy (brak w programie, zły kod); sesja + wylogowanie.

**3. Oferta (56 h)**  
Home (kategorie szybkiego dostępu, karuzela nowości, rekomendacje); lista kategorii; podkategorie; lista produktów (filtry, sort, aktywne filtry, siatka, paginacja); karta produktu (galeria, spec, opis, do koszyka); wyszukiwarka.

**4. Ulubione (9 h)**  
Toggle na listach i PDP; ekran listy ulubionych.

**5. Koszyk (12 h)**  
Pozycje, ilość, usuwanie; podsumowanie (produkty, dostawa, suma).

**6. Checkout (59 h)**  
Pasek 4 kroków;  
1) adres (zapisane, nowy, faktura VAT);  
2) dostawa (paczkomat, kurier, odbiór, punkt na mapie);  
3) płatność (BLIK, karta, przelew, pobranie, raty);  
4) podsumowanie (edycja, kod rabatowy, zgody);  
ekran potwierdzenia zamówienia.

**7. Nawigacja (8 h)**  
Bottom nav: **Start, Oferta, Ulubione, Koszyk** + routing.

**8–10.** Testy Android/iOS, store’y, integracja z realnym API, loading/error/empty.

---

## 4. Założenia (wiążące)

- API gotowe, przetestowane, udokumentowane — bez prac backendowych w tej wycenie.
- Zdjęcia i treści produktów z API.
- Bez opłat kont deweloperskich Google / Apple.
- Płatności i dostawy przez gotowe API/SDK dostawców.
- Zmiana zakresu w trakcie → zmiana czasu.

---

## 5. Design system — co bierzemy do v1

Źródło: `stitch_myriad_pro_design_system/satur_e_commerce_mobile/DESIGN.md` + odpowiadające ekrany HTML/PNG **w zakresie v1**.

### Brand / UI

- Styl: minimalistyczny / corporate modern, czytelność i gęstość użytkową.
- Primary navy (`#003684` / `#214ea2`), secondary cyan, białe tła, cienkie obrysy zamiast ciężkich cieni.
- Typografia: **Arimo** (zamiennik Myriad Pro); ceny jako osobna rola typograficzna.
- Layout: margin 16px, gutter 12px; produkty w siatce 2 kolumn; sticky CTA na dole.
- Bottom nav (zgodnie z wyceną + DESIGN.md): **4 sloty** — Start, Oferta, Ulubione, Koszyk (bez „Konto” w v1).
- Top bar: logo Satur na środku; ikony (m.in. powiadomienia — **tylko ikona**, bez listy w v1).

Uwaga: część plików HTML używa Inter / 5 tabów z „Konto” — to artefakty starej/szerszej grafiki; **nie implementujemy**.

---

## 6. Ekrany designu vs zakres

### W zakresie v1 (referencja UI)

| Folder designu | Rola |
|----------------|------|
| `ekran_startowy_poprawiony` | Powitanie, CTA logowania / dołączenia |
| `rejestracja_do_platformy_benefity_zakupowe` | Zgłoszenie do programu (e-mail) |
| `potwierdzenie_rejestracji_e_mail_wys_any` | Potwierdzenie wysłania e-maila |
| `logowanie_mobile_fix` | **Tylko layout/styl** — treść auth wg wyceny (bez hasła + kod), nie wg mockupu z hasłem |
| `ekran_g_wny_poprawione_karty_produkt_w_1_1` | Home |
| `oferta_kategorie` | Kategorie główne |
| `elektronika_podkategorie` | Podkategorie |
| `smartfony_i_telefony_lista_produkt_w` | Lista produktów + filtry/sort |
| `karta_produktu` | PDP |
| `ulubione_lista_ycze` | Ulubione |
| `koszyk` | Koszyk |
| `adres_dostawy_pe_ny_widok` | Checkout krok 1 |
| `metoda_dostawy` | Checkout krok 2 |
| `metoda_p_atno_ci` | Checkout krok 3 |
| `podsumowanie_zam_wienia` | Checkout krok 4 |
| `dzi_kujemy_za_zam_wienie` | Potwierdzenie zamówienia |

### Poza v1 (design istnieje — nie budujemy)

- Konto: `moje_konto_dashboard`, `tw_j_profil_edycja`, `zmie_has_o`, `ksi_ka_adresowa`
- Zamówienia / zwroty: `historia_zam_wie`, `szczeg_y_zam_wienia`, `moje_zwroty_i_reklamacje`, `zg_o_zwrot_reklamacj`
- Powiadomienia (lista): `powiadomienia`
- B2B: `klienci_konto_firmowe`, `szczeg_y_klienta_b2b`, `konto_firmowe_dane_firmy`, `edytuj_dane_firmy_b2b`, `ustawienia_konta_firmowego`, `historia_zam_wie_firmowych`, `szczeg_y_zam_wienia_firmowego`

---

## 7. Rozstrzygnięte rozjazdy design ↔ wycena

| Temat | Design (stara/szeroka grafika) | Decja (wycena wygrywa) |
|-------|--------------------------------|-------------------------|
| Logowanie | E-mail + hasło; ekran zmiany hasła | **Bez hasła**: e-mail/login → **kod dostępu** z e-maila |
| Potwierdzenie rejestracji | „Link aktywacyjny” w copy | Zgłoszenie do programu + potwierdzenie wysłania e-maila; auth dalej przez kod |
| Bottom nav | Często 5 tabów (+ Konto) | **4 taby**: Start, Oferta, Ulubione, Koszyk |
| Powiadomienia | Pełna lista | Tylko **ikona** w top barze |
| Konto / historia / zwroty / B2B | Pełne flow w mockupach | **Poza v1** |
| Font w HTML | Czasem Inter | Tokeny z **DESIGN.md** (Arimo) |

Przy implementacji ekranu logowania: zachować look & feel (navy, pola, spacing), ale **flow i pola** jak w wycenie (kod, nie hasło).

---

## 8. Flow użytkownika v1 (kanoniczny)

```
Start
  ├─ Dołącz do programu → formularz e-mail → potwierdzenie wysłania
  └─ Zaloguj się → e-mail/login → kod dostępu → sesja
        │
        ▼
Home / Oferta / Search → kategorie → podkategorie → lista → PDP
        │                    └─ ulubione (toggle)
        ▼
Ulubione (lista)
        │
        ▼
Koszyk → Checkout:
  1. Adres dostawy (+ opcjonalnie faktura VAT)
  2. Metoda dostawy (paczkomat/mapa, kurier, odbiór)
  3. Metoda płatności (BLIK, karta, przelew, pobranie, raty)
  4. Podsumowanie (edycja, kod rabatowy, zgody) → płatność
        │
        ▼
Dziękujemy za zamówienie
```

Nawigacja główna: Start | Oferta | Ulubione | Koszyk.

---

## 9. Stack i kolejność pracy (przy starcie implementacji)

1. Fundamenty Flutter + środowiska + Design System + komponenty  
2. Warstwa API (HTTP, sesja, błędy)  
3. Auth / dołączenie do programu  
4. Oferta (home → kategorie → lista → PDP → search)  
5. Ulubione  
6. Koszyk  
7. Checkout end-to-end  
8. Nawigacja / spójność  
9. Testy + Android release  
10. iOS + stabilizacja  

---

## 10. Pliki źródłowe

| Plik / folder | Rola |
|---------------|------|
| `docs/Wycena_Satur_Flutter.pdf` | Zakres i wycena — **nadrzędne** |
| `docs/stitch_myriad_pro_design_system/` | UI / DS (filtrowane przez zakres v1) |
| `docs/PODSUMOWANIE_ZAKRESU_V1.md` | Ten dokument — zrozumienie do powrotu przy pracy |
| `README.md` / `Makefile` | Setup Flutter, Docker (bez DB), API → `../satur:5051` |

---

## 11. Środowisko developerskie (ustalone)

- Flutter stable w `~/development/flutter` (bez sudo).
- Android SDK w `~/Android/Sdk` (SDK 36) — priorytet Android.
- Docker w tym repo: **tylko tooling**, **bez bazy**.
- API: projekt `../satur` (Sylius), port **5051** (`make satur-api-check`).
- Linux desktop (clang/cmake) — nie wymagane dla v1 Android; pominięte celowo (wymagałoby apt/sudo).

---

*Dokument odzwierciedla uzgodnienie: wycena ostateczna > grafika (starsza wersja zakresu).*
