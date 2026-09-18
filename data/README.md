# Dane — Online Retail II

Ten folder nie zawiera pliku z danymi, plik jest za duży ( ok 91 MB) i prawa do niego są zastrzeżone. W obecnym pliku podajemy instrukcję pobrania.

## Źródło pliku: Kaggle \- zalecane od razu w formacie CSV: [https://www.kaggle.com/datasets/mashlyn/online-retail-ii-uci](https://www.kaggle.com/datasets/mashlyn/online-retail-ii-uci) 

Pobierz plik **`online_retail_II.csv`** i umieść go w tym folderze (`data/`), tak aby ścieżka wyglądała następująco: data/online\_retail\_II.csv

Źródło oryginalne (UCI, plik w formacie Excel z dwoma arkuszami): [https://archive.ics.uci.edu/dataset/502/online+retail+ii](https://archive.ics.uci.edu/dataset/502/online+retail+ii)

## Opis zbioru

- Wszystkie transakcje sklepu internetowego   
- Zakres dat: 2009-12-01 – 2011-12-09.  
- \~1,07 mln wierszy (pozycje na fakturach), 43 kraje.

Kolumny: `Invoice`, `StockCode`, `Description`, `Quantity`, `InvoiceDate`, `Price`, `Customer ID`, `Country`. Faktury z prefiksem `C` to anulowania.

## Jak wczytać do PostgreSQL

Instrukcja importu (tworzenie tabel, import CSV, czyszczenie) znajduje się w pliku [`../sql/projekt_online_retail.sql`](../sql/projekt_online_retail.sql), Etap 1\.

## Licencja i cytowanie

Zbiór udostępniony na licencji Creative Commons Attribution 4.0 International (CC BY 4.0) — pozwala na dowolne wykorzystanie i adaptację pod warunkiem podania źródła.

Chen, D. (2012). *Online Retail II* \[Dataset\]. UCI Machine Learning Repository. [https://doi.org/10.24432/C5CG6D](https://doi.org/10.24432/C5CG6D)  
