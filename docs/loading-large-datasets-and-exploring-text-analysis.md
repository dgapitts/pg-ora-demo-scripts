## Loading large datasets and exploring text analysis with Ulysses
   
I'm sure there are many ways to do this, some of which are going to be more efficient, but here is my "first attempt"
* Download .txt version of [Ulysses-James-Joyce from gutenberg](https://www.gutenberg.org/files/4300/4300-0.txt)
* add line numbers: `cat -n`   
* I want to use # as my delimiter, so I removed this line
```
~/projects/pg-ora-demo-scripts/docs $ grep '#' Ulysses-James-Joyce-1922.txt
Release Date: December 27, 2001 [eBook #4300]
~/projects/pg-ora-demo-scripts/docs $
```
* I then remove "leading white" (before line number): `awk '{$1=$1;print}'`
* Finally replace first space with a # (a better delimiter than a comma in our ".csv" file ) 
```
~/projects/pg-ora-demo-scripts/docs $ cat -n  Ulysses-James-Joyce-1922.txt| grep -v '#'| awk '{$1=$1;print}'|sed 's/ /#/'>Ulysses-Jame-Joyce-1922.csv
~/projects/pg-ora-demo-scripts/docs $ head Ulysses-James-Joyce-1922.csv
1#The Project Gutenberg eBook of Ulysses, by James Joyce
2#
3#This eBook is for the use of anyone anywhere in the United States and
4#most other parts of the world at no cost and with almost no restrictions
5#whatsoever. You may copy it, give it away or re-use it under the terms
6#of the Project Gutenberg License included with this eBook or online at
7#www.gutenberg.org. If you are not located in the United States, you
8#will have to check the laws of the country where you are located before
9#using this eBook.
10#
```

Next 

```
CREATE TABLE ulysses (line_num integer, line_text varchar);
```

Finally the load file, using copy and a # delimiter ... just over 33K rows

```
dave=# \copy ulysses FROM 'Ulysses-James-Joyce-1922.csv' DELIMITER '#' CSV
COPY 33209
```

Using a simple text search, there are two direct references to Amsterdam, one to Barcelona

```
dave=# select line_num, line_text from ulysses where lower(line_text) like '%amsterdam%';
 line_num |                               line_text
----------+------------------------------------------------------------------------
    21018 | burning part produced Fritz of Amsterdam, the thinking hyena. _(He
    27922 | End_ by Jans Pieter Sweelinck, a Dutchman of Amsterdam where the frows
(2 rows)

dave=# select line_num, line_text from ulysses where lower(line_text) like '%barcelona%';
 line_num |                            line_text
----------+------------------------------------------------------------------
     2157 | Postprandial. There was a fellow I knew once in Barcelona, queer
(1 row)
```

but over 30 to Paris, which in 1922 was arguably the most exciting city in the world and clearly dear to Joyce 
```
dave=# select line_num, line_text from ulysses where lower(line_text) like '%paris%' and lower(line_text) not like '%parish%' and lower(line_text) not like '%comparison%';
 line_num |                                line_text
----------+-------------------------------------------------------------------------
      565 | —O, damn you and your Paris fads! Buck Mulligan said. I want Sandycove
     1303 | he had read, sheltered from the sin of Paris, night by night. By his
     1648 | Paris_, 1866. Elfin riders sat them, watchful of a sign. He saw their
     1730 | On the steps of the Paris stock exchange the goldskinned men quoting
     2083 | MacMahon. Son of the wild goose, Kevin Egan of Paris. My father’s a
     2103 | tone: when I was in Paris; _boul’ Mich’_, I used to. Yes, used to carry
     2141 | Paris rawly waking, crude sunlight on her lemon streets. Moist pith of
     2147 | _pus_ of _flan bréton_. Faces of Paris men go by, their wellpleased
     2189 | Paree he hides, Egan of Paris, unsought by any save by me. Making his
     2426 | shoe went on you: girl I knew in Paris. _Tiens, quel petit pied!_
     2468 | known to man. Old Father Ocean. _Prix de Paris_: beware of imitations.
     6410 | —Paris, past and present, he said. You look like communards.
     8951 | poems Stephen MacKenna used to read to me in Paris. The one about
     9006 | manners. Elizabethan London lay as far from Stratford as corrupt Paris
     9016 | bankside. The bear Sackerson growls in the pit near it, Paris garden.
     9181 | Paris: the wellpleased pleaser.
     9959 | Hurrying to her squalid deathlair from gay Paris on the quayside I
    10127 | Newhaven-Dieppe, steerage passenger. Paris and back. Lapwing. Icarus.
    11807 | of Paris. Late lieabed under a quilt of old overcoats, fingering a
    15956 | Egan of Paris. You wouldn’t see a trace of them or their language
    21407 | after dark on Paris boulevards, insulting to any lady. I have it still.
    21825 | with long flowing crimson tail, richly caparisoned, with golden
    23333 | toe, as worn in Paris.
    24425 | the room doing it! Ride a cockhorse. You could hear them in Paris and
    24500 | LYNCH: Let him alone. He’s back from Paris.
    24515 | princesses like are dancing cancan and walking there parisian
    24615 | Beaufort’s Ceylon, prix de Paris. Dwarfs ride them, rustyarmoured,
    25199 | _(Kevin Egan of Paris in black Spanish tasselled shirt and peep-o’-day
    25287 | likely to meet these necessary evils? _Ça se voit aussi à Paris._ Not
    27188 | air of some consternation remembering he had just come back from Paris,
    28040 | Music, literature, Ireland, Dublin, Paris, friendship, woman,
    31794 | Stanhope sent me from the B Marche paris what a shame my dearest
    32054 | on board I wore that frock from the B Marche paris and the coral
    32858 | Trieste-Zurich-Paris
(34 rows)
```

although there is at lesat one false positive above

```
   21825 | with long flowing crimson tail, richly caparisoned, with golden
```   