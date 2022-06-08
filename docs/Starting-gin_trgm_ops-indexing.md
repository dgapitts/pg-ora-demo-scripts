## Starting gin_trgm_ops indexing


### operator class "gin_trgm_ops" does not exist for access method "gin"

The fix for
```
dave=#  CREATE INDEX CONCURRENTLY ulysses_trigram on ulysses using gin(line_text, gin_trgm_ops); 
ERROR:  operator class "gin_trgm_ops" does not exist for access method "gin"
```
was
```
dave=# CREATE EXTENSION pg_trgm;
CREATE EXTENSION
```

### My first gin_trgm_ops

adding a gin_trgm_ops on the whole of ulysses takes less than 1 sec (on my very old laptop)
```
dave=# \timing on
Timing is on.
dave=# CREATE INDEX CONCURRENTLY ulysses_trigram on ulysses using gin(line_text  gin_trgm_ops); 
CREATE INDEX
Time: 803.612 ms
```

Now I was wondering about Deasy being a West Briton ([infered or explicit somewhere in Ulysses?](https://davetravelogue.blogspot.com/2022/06/joyces-great-european-novel-and-that.html))

```
dave=# select line_num, line_text from ulysses where line_text ILIKE '%brit%';
 line_num |                                line_text
----------+-------------------------------------------------------------------------
     1035 | —The imperial British state, Stephen answered, his colour rising, and
     1065 | —Of course I’m a Britisher, Haines’s voice said, and I feel as one. I
     5495 | and paid, for local, provincial, British and overseas delivery.
     6223 | British or Brixton. The word reminds one somehow of fat in the fire.
     7270 | for a penny and broke the brittle paste and threw its fragments down
    14757 | God of the United Kingdom of Great Britain and Ireland and of the
    14758 | British dominions beyond the sea, queen, defender of the faith, Empress
    15132 | Kratchinabritchisitch, Borus Hupinkoff, Herr Hurhausdirektorpresident
    16144 | —That’s your glorious British navy, says the citizen, that bosses the
    16176 | crops that the British hyenas bought and sold in Rio de Janeiro. Ay,
    16287 | puma (a far nobler king of beasts than the British article, be it said
    16387 | heartfelt thanks of British traders for the facilities afforded them in
    16390 | translated by the British chaplain, the reverend Ananias Praisegod
    16392 | cordial relations existing between Abeakuta and the British empire,
    16651 | Brittany and S. Michan and S. Herman-Joseph and the three patrons of
    16670 | Britain street chanting the introit in _Epiphania Domini_ which
    16679 | Kiernan and Co, limited, 8, 9 and 10 little Britain street, wholesale
    20045 | mère m’a mariée._ British Beatitudes! _Retamplatan digidi boumboum_.
    20905 | Come on, you British army!
    21090 | one of Britain’s fighting men who helped to win our battles. Got his
    21104 | was a J. P. I’m as staunch a Britisher as you are, sir. I fought with
    21115 | connected with the British and Irish press. If you ring up...
    21231 | acclimatised Britisher, he had seen that summer eve from the footplate
    21236 | and ninepence a dozen, innocent Britishborn bairns lisping prayers to
    21241 | times the strains of the organtoned melodeon Britannia metalbound with
    22020 | Kippur Hanukah Roschaschana Beni Brith Bar Mitzvah Mazzoth Askenazim
    26932 | advised them, how much palmoil the British government gave him for that
    27876 | political celebrity of that ilk, as it struck him, the two identical
    28457 | In Bernard Kiernan’s licensed premises 8, 9 and 10 little Britain
    29197 | Austrian army, proximate, a hallucination, lieutenant Mulvey, British
    30087 | containing the Encyclopaedia Britannica and New Century Dictionary,
    30283 | paper, perforate, Great Britain, 1855: 1 franc, stone, official,
    30343 | Packet Company (Laird line), British and Irish Steam Packet Company,
    30465 | Numerous. From clergyman, British naval officer, wellknown author, city
    31032 | Limited, 8, 9 and 10 Little Britain street, the erotic provocation and
(35 rows)

Time: 189.098 ms
```
