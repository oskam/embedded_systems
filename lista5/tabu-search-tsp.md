## Stałe: ##

- `n` - rozmiar danych, tzn. ilość wierzchołków w problemie grafowym TSP
- `d` - macierz nxn odeległości między miastami: `d(1,5)==d(5,1)` - odleglość między miastami 1 i 5
- `tabu[]` - lista tabu:
    - może być listą `tabu[n]` gdzie zapisjemy dla każdego miasta, w której iteracji zostało przestawione, wtedy `isTabbed(i) == true` => `iter-tabu[i] < p`, gdzie `iter` to numer aktualnej iteracji,
    > **UWAGA:** wartość początkowa musi być ustawiona na `-p` aby gdy `iter<p` wynik `iter-tabu[i]=iter-(-p)=iter+p > p` => nie jest zablokowany

    - może być listą `tabu[sqrt(n)][n+1]` gdzie zapisujemy ograniczoną ilosć pełnych permutacji, które są zakazane, przy przepełnieniu zgodnie z zasadą FIFO wyrzucamy najstarsze zapisy
- `iterations` - liczba iteracji, może zależeć od `n`
- `p` - długość kary przy wpisaniu na listę `tabu`, może zależeć od `iterations`
- `checks = sqrt(n)/x` - ilość sąsiadów do sprawdzenia, zależy od rozmiaru danych `n`, trzeba podzielić przez jakąś stałą `x` aby była to rozsądna wartość na danych ~ 15000
- `N` - zbiór określający sąsiedztwo, tzn. zbiór par indeksów trasy, których zamiana generuje sąsiada, jest on taki sam dla każdej trasy, wystrczy wyliczyć go raz

#### Dane ulegające zmianie w przebiegu algorytmu: ####

- `currentTour[n+1]` - obecnie badana trasa (której sąsiadów sprawdzamy)
- `currentCost` - koszt `currentTour`
- `bestTour[n+1]` - najlepsza obecnie znana trasa
- `bestCost` - koszt `bestTour`
- `neighborTour[n+1]` - trasa będąca obecnie sprawdzanym sąsiadem `currentTour`
- `neighborCost` - koszt `neighborTour`
- `bestNeighborTour[n+1]` - najlepszy znany sąsiad `currentTour`
- `bestNeighborCost` - koszt `bestNeighborTour`

---

## Algorytm: ##

```python
# wylicz początkowe przybliżenie bestTour (pamietać że bestTour[0]=bestTour[n]=1, bo zaczynamy i kończymy w pierwszym mieście)
bestTour = getbesttour()

bestCost = distance(bestTour)
currentTour = copy(bestTour)
bestNeighborTour = copy(bestTour)
currentCost = bestNeighborCost = bestCost

N = [(x,y) for x=1:len(currentTour)-3 for y=x+1:len(currentTour)-2]

for i = 0:iterations:

    currentTour = copy(bestNeighborTour)
    currentCost = bestNeighborCost
    Ncopy = copy(N)
    checked = 0

    while checked < checks:

        (x, y) = # losowa para indeksów z Ncopy
        # z Ncopy usuń (x, y)

        if not isTabbed(currentTour[x], currentTour[y]):

            checked += 1
            neighborTour = # currentTour z zamienionymi indeksami x, y
            neighborCost = distance(neighborTour)

            if neighborCost <= bestNeighborCost:

                bestNeighborCost = kopia neighborCost
                bestNeighborCost = neighborCost


        # zaktualizuj listę tabu dla currentTour[x], currentTour[y]

    if len(Ncopy) == 0:

        # tu można skończyć algorytm, bo całe sąsiedztwo obecnie badanego
        # rozwiązania jest zakazane, czyli nie ma już nic ciekawego,
        # albo wykonać skok w inne okolice permutując częściowo rozwiązanie
        # currentTour lub w inny sposób

    # musimy dodać do tabu pozostałe sąsiedztwo obecnie badanego rozwiazania
    for (x, y) in Ncopy:

        # zaktualizuj liste tabu dla currentTour[x], currentTour[y]

    if bestNeighborCost <= bestCost:

        bestTour = copy(bestNeighborTour)
        bestCost = bestNeighborCost

# wydrukuj bestCost na STDOUT
# wydrukuj bestTour na STDERR
```

#### Uwagi do algorytmu: ####

1. Stosuje zapis `copy(tour)` bo nie mam pewnosci czy przyrownanie po prostu nie powiaze dwóch nazw z jedną zmienną w Pythonie.
2. Gdy przez wiele iteracji nie nastąpi poprawa wyniku, możemy zwiększyć rozmiar sprawdzanego sąsiedztwa, przywracając wartość bazową gdy znajdziemy rozwiązanie lepsze. Licznik braku poprawy zerujemy gdy taka nastąpi, tzn. gdy znajdzemy `bestNeighborCost <= bestCost`.
3. Przy przeszukiwaniu tabu zależy nam na ekspansji, a nie eksploracji, dlatego warunek zamiany najlepszego wyniku to `<=`, żeby z tak samo dobrym wynikiem móc udać się w inną część przestrzeni rozwiązań dopuszczalnych i w niej szukać lepszych.
4. Na listę tabu dodajemy po sprawdzeniu rozwiązania, żeby nie zablokować sobie rozwiązania przed sprawdzeniem `isTabbed()`.
5. Oczywiście jeśli lista tabu zawiera co innego niż numer iteracji, w której dane miasto było przestawiane, należy odpowiednio zmienić sprawdzanie i dodawanie do tabu.

----
