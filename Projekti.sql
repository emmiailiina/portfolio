CREATE TABLE Huolto (
HuoltoID INTEGER NOT NULL,
Tyyppi TEXT CHECK (Tyyppi IN ('Määräaikaishuolto', 'Korjaus')),
PRIMARY KEY (HuoltoID)
);

CREATE TABLE Toimenpide (
ToimenpideID INTEGER NOT NULL,
Kesto REAL NOT NULL,
HuoltoID INTEGER NOT NULL,
PRIMARY KEY (ToimenpideID),
FOREIGN KEY (HuoltoID) REFERENCES Huolto(HuoltoID)
);

CREATE TABLE Varaosa (
VaraosaID INTEGER NOT NULL,
Nimi TEXT NOT NULL,
Määrä INTEGER NOT NULL,
Kustannus REAL NOT NULL,
HuoltoID INTEGER NOT NULL,
PRIMARY KEY (VaraosaID),
FOREIGN KEY (HuoltoID) REFERENCES Huolto(HuoltoID)
);

CREATE TABLE Laitetyyppi (
TyyppiID INTEGER NOT NULL,
Nimi TEXT NOT NULL,
Malli TEXT, 
Valmistaja TEXT, -- Valmistaja ei ole pakollinen
Määrä INTEGER NOT NULL,
LaiteID INTEGER NOT NULL,
PRIMARY KEY (TyyppiID)
);

CREATE TABLE Laitekappale (
LaiteID INTEGER NOT NULL, 
LaitteenNimi TEXT NOT NULL,
TyyppiID INTEGER NOT NULL,
PRIMARY KEY (LaiteID),
FOREIGN KEY (TyyppiID) REFERENCES Laitetyyppi(TyyppiID)
);

CREATE TABLE Laitevaraus (
LaitevarausID INTEGER NOT NULL,
AloitusAika TEXT NOT NULL,
LopetusAika TEXT CHECK(AloitusAika <= LopetusAika), -- Tarkistetaan että aloitusaika ei ole myöhän lopetusaika
Määrä INTEGER NOT NULL,
HuoltoID INTEGER NOT NULL,
ToimenpideID INTEGER NOT NULL,
LaiteID INTEGER NOT NULL,
PRIMARY KEY (LaitevarausID),
FOREIGN KEY (HuoltoID) REFERENCES Huolto(HuoltoID),
FOREIGN KEY (ToimenpideID) REFERENCES Toimenpide(ToimenpideID),
FOREIGN KEY (LaiteID) REFERENCES Laitekappale(LaiteID)
);

CREATE TABLE Lasku (
LaskuID INTEGER NOT NULL,
Lähetetty TEXT NOT NULL, -- Lähetetty päivämäärä on pakollinen
Maksettu TEXT CHECK ( Maksettu >= Lähetetty), -- Tarkistetaan että maksettu aika ei ole ennen lähetettyä
Määrä€ REAL NOT NULL CHECK(Määrä€ > 0),
PRIMARY KEY (LaskuID)
);

CREATE TABLE Maksumuistutus (
MaksumuistutusID INTEGER NOT NULL,
Lähetetty TEXT NOT NULL,
Maksettu TEXT CHECK (Maksettu >= Lähetetty), -- Tarkistetaan että maksettu aika ei ole ennen lähetettyä
Lisämaksu REAL CHECK (Lisämaksu > 0), -- Lisämaksu ei ole pakollinen
LaskuID INTEGER NOT NULL,
PRIMARY KEY (MaksumuistutusID),
FOREIGN KEY (LaskuID) REFERENCES Lasku(LaskuID)
);

CREATE TABLE Omistaa ( 
OmistajaNumero INTEGER NOT NULL, -- onko foreign key? 
RekisteriNumero TEXT NOT NULL, -- Rekisterinumero on foreign key? 
PRIMARY KEY(OmistajaNumero, RekisteriNumero)
);

CREATE TABLE Auto (
RekisteriNumero TEXT NOT NULL,
KilometritAjettu REAL CHECK (KilometritAjettu > 0),
Merkki TEXT,
Malli TEXT,
PRIMARY KEY (RekisteriNumero)
);

CREATE TABLE Omistaja (
OmistajaNumero INTEGER NOT NULL, 
Nimi TEXT NOT NULL,
PuhelinNumero TEXT NOT NULL,
Sähköposti TEXT NOT NULL,
Hetu TEXT NOT NULL,
PRIMARY KEY (OmistajaNumero)
);

CREATE TABLE Asiakas (
Nimi TEXT,
AsiakasNumero INTEGER NOT NULL,
PuhelinNumero TEXT, -- Yhteystiedot eivät ole pakolliset
Hetu TEXT NOT NULL, -- onko foreign key?
Sähköposti TEXT, -- Yhteystiedot eivät ole pakolliset
Osoite TEXT, 
PRIMARY KEY (AsiakasNumero)
);

CREATE TABLE HuoltoVaraus (
HuoltoVarausID INTEGER NOT NULL,
Alkamisaika TEXT NOT NULL,
Päättymisaika TEXT CHECK (Päättymisaika >= Alkamisaika), -- Tarkistetaan että päättymisaika ei ole ennen alkamisaikaa
LaskuID INTEGER NOT NULL,
Rekisterinumero TEXT NOT NULL, -- Rekisterinumero on INT + STRING, on pakollinen ???
Asiakasnumero INTEGER NOT NULL, -- Pakollinen ???
HuoltoID INTEGER NOT NULL,
PRIMARY KEY (HuoltoVarausID),
FOREIGN KEY (Rekisterinumero) REFERENCES Auto(RekisteriNumero),
FOREIGN KEY (Asiakasnumero) REFERENCES Asiakas(AsiakasNumero),
FOREIGN KEY (HuoltoID) REFERENCES Huolto(HuoltoID),
FOREIGN KEY (LaskuID) REFERENCES Lasku(LaskuID)
);

CREATE TABLE Työntekijä (
TyöntekijäID INTEGER NOT NULL,
Työtunnit REAL NOT NULL, -- Työtunnit on ilmoitettava
Status TEXT CHECK (Status IN ('Vapaana', 'Ei_vapaana')) NOT NULL , -- Vapaana on ilmoitettava, Boolean vai DATE?
Nimi TEXT NOT NULL,
HuoltovarausID INTEGER NOT NULL,
PRIMARY KEY (TyöntekijäID),
FOREIGN KEY (HuoltovarausID) REFERENCES Huoltovaraus(HuoltoVarausID)
);

CREATE TABLE Poissaolo (
PoissaoloID INTEGER NOT NULL,
Syy TEXT CHECK (Syy IN ('EtukäteenSovittu', 'Sairaus')), -- syy EI pakollinen
Alkamisaika TEXT NOT NULL,
Päättymisaika TEXT CHECK (Päättymisaika >= Alkamisaika), -- Tarkistetaan että päättymisaika ei ole ennen alkamisaikaa
TyöntekijäID INTEGER NOT NULL,
PRIMARY KEY (PoissaoloID),
FOREIGN KEY (TyöntekijäID) REFERENCES Työntekijä(TyöntekijäID)
);


---------------------------------------------------------------------------------------------------------------------

-- Maksattomat laskut
CREATE INDEX MaksattomatIndex ON Maksumuistutus(MaksumuistutusID);

-- Korjaamon Myynti
CREATE INDEX LiikevaihtoIndex ON Lasku(LaskuID);

-- Varatut huollot
CREATE INDEX VarauksetIndex ON Huoltovaraus(HuoltoVarausID);

-- Varatut laitteet
CREATE INDEX VaratutLaitteetIndex ON Laitevaraus(LaitevarausID);

-- Auton tiedot
CREATE INDEX AutonTiedotIndex ON Auto(RekisteriNumero);

---------------------------------------------------------------------------------------------------------------------

-- Kuka ei ole paikalla näkymä
CREATE VIEW KukaEiPaikalla AS
SELECT Nimi FROM Työntekijä WHERE TyöntekijäID IN (SELECT TyöntekijäID FROM Poissaolo WHERE Alkamisaika <= CURRENT_TIMESTAMP AND (Päättymisaika >= CURRENT_TIMESTAMP OR Päättymisaika IS NULL));

-- Kuluvan kuukauden Liikevaihto
CREATE VIEW Liikevaihto AS
SELECT SUM(Määrä€) FROM Lasku WHERE (Maksettu >= datetime('now','start of month')) AND (Maksettu <= datetime('now','start of month','+1 month','-1 day'));

-- Asiakkaan nimet jolla on maksamaton lasku
CREATE VIEW MaksattomatAsiakkaat AS
SELECT nimi FROM Asiakas WHERE AsiakasNumero IN (SELECT Asiakasnumero FROM HuoltoVaraus WHERE LaskuID IN (SELECT LaskuID FROM Lasku WHERE Maksettu IS NULL))

---------------------------------------------------------------------------------------------------------------------

INSERT INTO Huolto
VALUES (89, 'Määräaikaishuolto');
INSERT INTO Huolto
VALUES (8983, 'Määräaikaishuolto');
INSERT INTO Huolto
VALUES (234, 'Korjaus');
INSERT INTO Huolto
VALUES (23832, 'Korjaus');
INSERT INTO Huolto
VALUES (83741, 'Korjaus');

INSERT INTO Toimenpide
VALUES (87, 23.1, 89);
INSERT INTO Toimenpide
VALUES (8, 1220.1, 8983);
INSERT INTO Toimenpide
VALUES (1, 240.90, 234);
INSERT INTO Toimenpide
VALUES (10, 800.3, 23832);
INSERT INTO Toimenpide
VALUES (14, 3000.15, 83741);

INSERT INTO Varaosa
VALUES (77, 'Ruuvi', 20, 1.89, 89);
INSERT INTO Varaosa
VALUES (1, 'Turbiini', 1, 180.23, 8983);
INSERT INTO Varaosa
VALUES (23, 'LEDI-valo', 4, 39.4, 234);
INSERT INTO Varaosa
VALUES (93, 'jarrurumpu', 2, 300.1, 23832);
INSERT INTO Varaosa
VALUES (2, 'Mutteri', 28, 2.36, 83741);

INSERT INTO Laitetyyppi
VALUES (0908, 'NOSTURI', '4E','SCANIA', 34, 10);
INSERT INTO Laitetyyppi
VALUES (0907, 'TUNKKI','9IO','VOLVO', 20, 11);
INSERT INTO Laitetyyppi
VALUES (0906, 'MITTARI','4ERL','AUDI', 2, 12);
INSERT INTO Laitetyyppi
VALUES (0905, 'AUTONOSTIN','SMART','WIHURI', 10, 13);
INSERT INTO Laitetyyppi
VALUES (0904, 'PYÖRÄNSUUNTAUSLAITE','EXLE','QUICK', 30, 14);

INSERT INTO Laitekappale
VALUES (55,'PYÖRÄNSUUNTAUSLAITE',0904);
INSERT INTO Laitekappale
VALUES (22,'NOSTURI',0908);
INSERT INTO Laitekappale
VALUES (11,'TUNKKI',0907);
INSERT INTO Laitekappale
VALUES (33,'MITTARI',0906);
INSERT INTO Laitekappale
VALUES (44,'AUTONOSTIN',0905);

INSERT INTO Laitevaraus
VALUES (1, '2022-03-01 14:00:00', '2022-03-02 14:00:00', 1, 89, 87, 55);
INSERT INTO Laitevaraus
VALUES (2, '2022-03-22 08:00:00', '2022-03-22 16:00:00', 2, 8983, 8, 22);
INSERT INTO Laitevaraus
VALUES (3, '2022-04-02 08:00:00', '2022-04-02 16:00:00', 2, 234, 1, 11);
INSERT INTO Laitevaraus
VALUES (4, '2022-04-15 08:00:00', '2022-04-15 16:00:00', 2, 23832, 10, 33);
INSERT INTO Laitevaraus
VALUES (5, '2022-04-17 08:00:00', '2022-04-17 16:00:00', 1, 83741, 14, 44);
INSERT INTO Laitevaraus
VALUES (6, '2022-05-10 08:00:00', '2022-05-15 16:00:00', 1, 83741, 14, 44);

INSERT INTO Lasku
VALUES (1, '2022-03-02 23:37:14', CURRENT_TIMESTAMP, 1000.00);
INSERT INTO Lasku
VALUES (2, '2022-03-22 16:00:00', '2022-04-10 23:37:14', 1550.00);
INSERT INTO Lasku
VALUES (3, '2022-04-02 16:00:00', NULL, 420.69);
INSERT INTO Lasku
VALUES (4, '2022-04-15 16:00:00', CURRENT_TIMESTAMP, 230.90);
INSERT INTO Lasku
VALUES (5, '2022-04-17 16:00:00', NULL, 1500.00);

INSERT INTO Maksumuistutus
VALUES (1, '2022-03-15 23:37:14', NULL, 70.00, 1);
INSERT INTO Maksumuistutus
VALUES (2, '2022-03-28 23:37:14', NULL, 70.00, 1);
INSERT INTO Maksumuistutus
VALUES (3, '2022-04-07 23:37:14', '2022-04-10 23:37:14', 150.50, 2);
INSERT INTO Maksumuistutus
VALUES (4, '2022-04-15 23:37:14', CURRENT_TIMESTAMP, 70.00, 1);
INSERT INTO Maksumuistutus
VALUES (5, '2022-04-17 23:37:14', NULL, 50.00, 3);

INSERT INTO Omistaa
VALUES (889098,'AKU-313');
INSERT INTO Omistaa
VALUES (29381,'HUI-847');
INSERT INTO Omistaa
VALUES (339842,'LOL-112');
INSERT INTO Omistaa
VALUES (746327,'HEH-555');
INSERT INTO Omistaa
VALUES (87364,'OOO-456');

INSERT INTO Auto
Values ('AKU-313',20000.0, 'Audi','S5');
INSERT INTO Auto
Values ('HUI-847',120000.0, 'BMW','E36');
INSERT INTO Auto
Values ('LOL-112',320000.5, 'Toyota','Prius');
INSERT INTO Auto
Values ('HEH-555',4000.2, 'Kia','Soul');
INSERT INTO Auto
Values ('OOO-456',100.0, 'Ferrari','812 GTS');

INSERT INTO Omistaja
Values (889098,'Onni Manni','050-287-3982' , 'onnimanni@gmail.com', '230199-297H');
INSERT INTO Omistaja
Values (29381,'Julietta Juntunen','0448829964','jullipulli@gmail.com', '031279-342S');
INSERT INTO Omistaja
Values (339842,'Keijo Juntunen','0507328932','keijokeke@gmail.com', '040266-342Q');
INSERT INTO Omistaja
Values (746327,'Minna Mäisti','045 837 9827','minde111@gmail.com', '290495-837J');
INSERT INTO Omistaja
Values (87364,'Heikki Komarov','050 298 3287','heikki_k@gmail.com', '300892-238C');

INSERT INTO Asiakas
Values ('Pentti Penttinlä', 92893, '0908372311','300986-387H','penttipena@gmail.com', 'Niittäjäntie 3 Helsinki');
INSERT INTO Asiakas
Values ('Onni Omena', 33, '031292331','120393-836B','omenaonni@gmail.com', 'Tiekatu 42 C Kotka');
INSERT INTO Asiakas
Values ('Emmi Aurinkoinen', 837, '043988573','230692-943E','aurinkoemmi@gmail.com', 'Kujakierros 2 Kerimäki');
INSERT INTO Asiakas
Values ('Pekka Pekala', 28371, '0447568879','111149-948J','pekkapekka132@gmail.com', 'Sammuttajantie 22 D Lahti');
INSERT INTO Asiakas
Values ('Keijo Juntunen', 1, '0408397617','230378-931H','keijokoo9u@gmail.com', 'Kelotie 100 Jaala');

INSERT INTO Huoltovaraus
VALUES (1, '2022-03-01 14:00:00', '2022-03-02 14:00:00', 1, 'AKU-313', 92893, 89);
INSERT INTO Huoltovaraus
VALUES (2, '2022-03-22 08:00:00', '2022-03-22 16:00:00', 2, 'HUI-847', 33, 8983);
INSERT INTO Huoltovaraus
VALUES (3, '2022-04-02 08:00:00', '2022-04-02 16:00:00', 3, 'LOL-112', 837, 234);
INSERT INTO Huoltovaraus
VALUES (4, '2022-04-15 08:00:00', '2022-04-15 16:00:00', 4, 'HEH-555', 28371, 23832);
INSERT INTO Huoltovaraus
VALUES (5, '2022-04-17 08:00:00', '2022-04-17 16:00:00', 5, 'OOO-456', 1, 83741);

INSERT INTO Työntekijä
VALUES (1, 88, 'Vapaana', 'Heikki Heikkilä', 1);
INSERT INTO Työntekijä
VALUES (2, 54, 'Vapaana', 'Jukka Jukkalainen', 2);
INSERT INTO Työntekijä
VALUES (3, 72, 'Vapaana', 'Kirsi Kirsikirsi', 3);
INSERT INTO Työntekijä
VALUES (4, 77, 'Vapaana', 'Maija Maijamaija', 4);
INSERT INTO Työntekijä
VALUES (5, 90, 'Vapaana', 'Sari Sarisarisari', 5);
INSERT INTO Työntekijä
VALUES (6, 15, 'Ei_vapaana', 'Laiska Heppu', 1);
INSERT INTO Työntekijä
VALUES (7, 0, 'Ei_vapaana', 'Sairas Matti', 1);

INSERT INTO Poissaolo
VALUES (1, 'EtukäteenSovittu', '2022-06-09 00:00:00', '2022-06-12 00:00:00', 2);
INSERT INTO Poissaolo
VALUES (2, 'EtukäteenSovittu', '2022-08-10 00:00:00', '2022-08-30 00:00:00', 1);
INSERT INTO Poissaolo
VALUES (3, 'Sairaus', '2022-03-04 00:00:00', '2022-03-06 00:00:00', 6);
INSERT INTO Poissaolo
VALUES (4, 'Sairaus', '2022-04-02 00:00:00', '2022-04-08 00:00:00', 6);
INSERT INTO Poissaolo
VALUES (5, 'Sairaus', '2022-05-09 23:37:14', NULL, 6);


---------------------------------------------------------------------------------------------------------------------

-- 1. Hankitaan uusi laite
SELECT Count(TyyppiID)
FROM Laitetyyppi
WHERE Malli = 'R-Series';

--Lisätään uusi laite tietokantaan koska COUNT = 0
INSERT INTO Laitekappale
VALUES(6,'KUORMA-AUTO', 6);
INSERT INTO Laitetyyppi
VALUES(6, 'KUORMA-AUTO', 'R-Series', 'Scania', 1, 6);


-- 2. Lähetä maksumuistutus maksattomille asiakkaille *
SELECT LaskuID FROM HuoltoVaraus WHERE LaskuID IN (SELECT LaskuID FROM Lasku WHERE Maksettu IS NULL);

-- Lähetetään maksumuistutus LaskuID: 3, 5
INSERT INTO Maksumuistutus
VALUES  (6, CURRENT_TIMESTAMP, NULL, 50.00, 3), (7, CURRENT_TIMESTAMP, NULL, 50.00, 5);


-- 3. Ahkeimmalle työntekijälle lomaa juhannusviikolla ja laiskimmalle työntekijälle annetaan potkut

-- Eniten työtunteja
SELECT TyöntekijäID, MAX(Työtunnit)
FROM Työntekijä

/*
TyöntekijäID	MAX(Työtunnit)
5	            90
*/

-- Lisätään juhannukseen viikon lomaa
INSERT INTO Poissaolo
VALUES (6, 'EtukäteenSovittu', '2022-06-20 00:00:00', '2022-06-27 00:00:00', 5);

-- Vähiten työtunteja
SELECT TyöntekijäID, MIN(Työtunnit)
FROM Työntekijä

/*
TyöntekijäID	MIN(Työtunnit)
7	            5
*/

-- Poistetaan ensin poissaolo-taulusta
DELETE FROM Poissaolo WHERE TyöntekijäID = 7;
-- Annetaan viimein potkut
DELETE FROM Työntekijä WHERE TyöntekijäID = 7;

-- 4. Tehdään uusi pika-huoltovaraus

-- Mitkä laitteet ovat välittömästi vapaana ja mitä mallia
SELECT Nimi, Malli, Valmistaja
FROM Laitetyyppi
WHERE TyyppiID IN (SELECT TyyppiID
FROM Laitekappale
WHERE LaiteID IN (SELECT LaiteID
FROM Laitevaraus
EXCEPT
SELECT LaiteID
FROM Laitevaraus
WHERE LopetusAika >= CURRENT_TIMESTAMP))

/*
Nimi	            Malli	Valmistaja
PYÖRÄNSUUNTAUSLAITE	EXLE	QUICK
MITTARI	            4ERL	AUDI
TUNKKI	            9IO	    VOLVO
NOSTURI	            4E	    SCANIA
*/

-- Luodaan ensin lasku
INSERT INTO Lasku
VALUES (6, CURRENT_TIMESTAMP, NULL, 555.00);

-- Lisätään sitten uusi huoltovaraus
INSERT INTO Huoltovaraus
VALUES (6, datetime('now'), datetime('now', '+1 day'), 6, 'AKU-313', 837, 8983);

-- Varataan laitteet
INSERT INTO Laitevaraus
VALUES (7, datetime('now'), datetime('now', '+1 day'), 1, 8983, 8, 55);

-- 5. Anna kannattavimmalle asiakkaalle alennusta
SELECT Asiakasnumero, Määrä€
FROM Huoltovaraus
INNER JOIN Lasku ON Lasku.LaskuID=Huoltovaraus.LaskuID
ORDER BY Määrä€ DESC;

/*
Asiakasnumero	Määrä€
33	            1550
1	            1500
92893	        1000
837	            555
837	            420.69
28371	        230.9
*/

-- Anna asiakkaalle 33 100€ alennusta
UPDATE Lasku
SET Määrä€ = 1450
WHERE LaskuID IN (SELECT LaskuID FROM Huoltovaraus
WHERE Asiakasnumero = '33');

-- 6. Myydään puolet kalliista varaosista
SELECT VaraosaID, MAX(Määrä + Kustannus)
FROM Varaosa

/*
VaraosaID	MAX(Määrä + Kustannus)	määrä
93	        302.1	                2
*/

UPDATE Varaosa
SET määrä = 1
WHERE VaraosaID = 93;

-- 7. Laitetyyppi 906 rikkoutui

--tarkistetaan oliko Laite varattu toukokuuksi
SELECT *
FROM Laitevaraus
WHERE LaiteID IN (SELECT LaiteID
FROM Laitekappale
WHERE TyyppiID = 906) AND (AloitusAika >= '2021-05-01' AND LopetusAika <= '2021-05-30');
/* Output:
0
*/

--Tarkistetaan montako laitetta on jäljellä 
SELECT TyyppiID, Määrä
FROM Laitetyyppi
WHERE tyyppiID = 906

/* Output:
TyyppiID	Määrä
906	        2
*/

-- Asetetaan määräksi 1
UPDATE Laitetyyppi
SET määrä = 1
WHERE TyyppiID = 0906;




