---
uuid: 99fd40e2-50d5-4e9f-a167-1de49b7eb3bd
title: "Notes filosòfiques sobre la IA 1: forma sense contingut"
date:   2025-08-22T18:00:00+0200
image:  tinman.png
image_caption: |-
  L'Home de Llauna amb l'Alícia i l'Espantaocells, a _Illustrations for the Wonderful Wizard of Oz_ de [W. W. Denslow](https://en.wikipedia.org/wiki/W._W._Denslow) (1900).
categories: Cibernètica
---

_El que segueix són unes notes intentant entendre els models de llenguatge extensos (_large language models_) amb l'ajuda de diferents teories filosòfiques. Sóc completament fora del meu element, així que aquest text ha de ser tractat com a experimental._

_Com el títol implica, potser en seguiran més._

[[toc]]

## Els models de llenguatge extensos són models que completen

Quan un usuari escriu una petició, o _prompt_, el xatbot contesta amb una resposta. Aquesta és la base de la IA generativa moderna tal com la coneix la majoria de gent. Aquesta interacció és útil perquè pots fer una pregunta i obtenir una resposta, o descriure una tasca i obtenir-ne el resultat.

Això dona la sensació d'intel·ligència, ja que el bot pot fer tasques molt complexes. Des de resumir textos llargs a una velocitat increïble, fins a mantenir una conversa interessant, programar un algorisme o resoldre un problema matemàtic difícil. Com ho van fer les empreses que fan aquests bots perquè poguessin fer tot això?

La resposta no és un programa increïblement dens, sinó un truc enginyós: el bot simplement ha après quina és la paraula més probable que segueix a una frase.

És clar que és més complex que això[^tokens][^attention], però aquesta n'és l'essència. El bot mira la petició de l'usuari, i després afegeix la primera paraula de la resposta. I després una altra, i una altra. Per això també s'anomenen models _que completen._[^transformer]

En el seu nucli, els xatbots només saben afegir una paraula. Però ho fan _molt bé._ El seu món sencer és afegir-ne només una, la perfecta. Després ho tornen a fer. Això pot generar diverses preguntes. Com és possible que frases coherents, o fins i tot idees profundes, es puguin crear així, i no disbarats? Doncs, de la mateixa manera que el joc del [cadàver exquisit](https://ca.wikipedia.org/wiki/Cad%C3%A0ver_exquisit), afegint una paraula rere l'altra.

## Forma sense contingut: Searle

Que ho _saben_ els models de llenguatge extensos, el que diuen? I _nosaltres,_ sabem el que diem?

La referència més directa als xatbots la trobem a l'argument de l'[habitació xinesa](https://ca.wikipedia.org/wiki/Habitaci%C3%B3_xinesa) de **John Searle**. Vindria a ser així: la teva feina és estar en una habitació, amb un llibre molt gran. Algú et llença una targeta amb text en xinès, i s'espera que responguis, també en xinès. Però tu no en saps, de xinès![^xines] Per sort, tens el llibre: només has de buscar les regles que s'apliquen als símbols que t'han donat, i seguir-les per obtenir uns altres símbols xinesos igualment enigmàtics com a resposta.[^bullshitjobs]

Et sona? És més o menys el que fan els xatbots. No tenen ni idea de què és cada símbol, ni què vol dir tota la frase. Ni tan sols divideixen frases en paraules com fem nosaltres\![^tokens] Només segueixen regles. Amb aquest exemple, Searle argumentava que els models d'intel·ligència artificial són incapaços d'entendre.

En altres paraules, els xatbots només deixen anar _bajanades._ Això és diferent de mentir, perquè mentir requereix comprensió. Les al·lucinacions són un dels problemes més grans dels models de llenguatge, perquè no estan dissenyats pensant en els conceptes de _veritat_ o _coneixement._ Són lloros estocàstics, trossos de quòniam meravellosos, jugadors professionals del cadàver exquisit.

## Paraules buides: Plató, Aristòtil

Hi ha una rica tradició filosòfica europea de menyspreu per les bajanades i l'absurd, començant amb Sòcrates i Plató:

>Sòcrates: Per consegüent, pel que fa a totes les altres arts la situació de l'orador i de la retòrica és la mateixa. De les coses en si, l'orador no cal que n'aprengui l'essència, però ha d'encertar un artifici persuasiu, de manera que davant dels no entesos sembli que en sap més que els entesos.
>--- _Gòrgias_ de Plató (p. 41 a _Diàlegs_[^plato]).

I afegeix sobre tot allò que és adulador i enganyós:

>Sòcrates: Això ho anomeno llagoteria, i dic que és quelcom vergonyós \[...\] perquè recerca el plaer sense considerar el bé. I afirmo que no és una art sinó una pràctica, perquè no té cap raó per oferir a qui dóna el que dóna referent a la naturalesa de tot això, de manera que no pot aclarir-ne la causa. Jo dic que no és cap art allò que és irracional.
>--- _Gòrgias_ de Plató (p. 48 a _Diàlegs_[^plato]).

Per a **Plató,** l'aparença de saviesa sense coneixement real és només una "pràctica de l'adulació", fingir en lloc de ser. I, vaja, com haurien odiat ell i Sòcrates els xatbots! Els oradors definitius, paraules completament desconnectades del coneixement real.

**Aristòtil** també considera el _logos_ (la raó) l'estructura d'un argument, mentre que el _pathos_ i _l'ethos_ hi afegeixen persuasió emocional i credibilitat. En aquest context, qualsevol discurs sense _logos_, fet de cadenes de paraules connectades per probabilitat, s'esfondraria. I de fet, així passa si pressiones una mica un xatbot.

## Xerrameca: Kierkegaard, Heidegger

Aquest torrent de paraules buit de significat, tant en el sentit de coneixement com d'intenció, segurament irritaria certs filòsofs amb poca paciència per la xerrameca. Per a **Søren Kierkegaard,** la quantitat de _snak_ (xerrameca) ja era insuportable al segle XIX:

> Què és la xerrameca? És l'anul·lació de la disjunció apassionada entre callar i parlar. Només la persona que pot romandre essencialment en silenci pot parlar essencialment, pot actuar essencialment. El silenci és interioritat. La xerrameca s'avança al parlar essencial, i expressar la reflexió té un efecte debilitador sobre l'acció en avançar-se-li.
>--- _Una crítica litèraria_ per S. Kierkegaard (trad. pròpia, p. 36 a _Søren Kierkegaards Skrifter_[^kierkegaard]).

Per a Kierkegaard, el silenci, la interioritat i la passió són l'essència d'una existència autèntica. Els models de llenguatge extensos, amb la seva xerrameca infinita de paraules buides i manca total d'albir, en són l'extrem oposat. No hi ha vida interior, no hi ha espai per a l'acció.

La xerrameca també era menyspreada per **Martin Heidegger.** Però primer cal entendre millor les seves idees, que són notòriament elusives. Tenia una teoria curiosa de com els humans perceben el món. Per exemple, que un arbre ens pot donar ombra o que una galeta és un dolç per menjar són les relacions primordials que tenim amb aquests objectes, mentre que la seva forma, color o mida són propietats derivades que empra la ment racional. I no només això: centrar-se en la teoria ens priva d'aquest coneixement pràctic.

Al cap i a la fi, per què _aprendre sobre un objecte_ quan pots _experimentar una acció_? La teoria et dona coneixement de segona mà, mediat per altres, mentre que la pràctica et dona una experiència autèntica, sense filtres. Això és el que Heidegger considera _autèntic,_ sent conscient del món.

Malauradament, vivim constantment distrets, fascinats pel món dels _altres,_ per la seva _xerrameca_ de segona mà. Al cap i a la fi, som animals socials i no és possible experimentar-ho tot directament, hem d'aprendre moltíssim. Però aquest coneixement, un cop circula, és desconnectat, poc fiable, superficial —en un sentit pràctic— i ens pot distreure de l'experiència primordial.

> El que es diu en la xerrameca com a tal s'escampa en cercles més amplis i adquireix un caràcter autoritari. Les coses són així perquè algú ho diu. La xerrameca és constituïda precisament per aquest xafardedeig i transmetre la paraula, un procés pel qual la seva carència inicial de fonament es veu agreujada fins a convertir-se en completa manca de fonament. I de fet aquesta xerrameca no es limita al xafardeig oral, sinó que fins i tot s'estén al que escrivim, on pren la forma de "gargot". En aquest darrer cas el xafardeig no es basa tant en rumors. S'alimenta de lectures superficials. La comprensió mitjana del lector mai no podrà decidir què ha estat extret de fonts primordials amb esforç i què és només xerrameca.
>--- _Ésser i temps_ de Martin Heidegger (trad. pròpia, p. 169 a [^heidegger]).

Per això, des del punt de vista de Heidegger, els models de llenguatge extensos serien màquines de pura _xerrameca._ Les seves paraules de tercera mà estan desconnectades del món, completament inautèntiques. Com més fem servir un xatbot, més ens impedeix experimentar directament el món.

## Notes

[^tokens]: Els models de llenguatge extensos fan servir tokens, que són símbols més petits que paraules, per [raons complicades](https://en.wikipedia.org/wiki/Large_language_model#Tokenization). Per exemple, així és com ChatGPT 4 llegeix una frase: "Un| fant|asma| ronda| per| Europa|:| el| fant|asma| del| comun|isme|.". [Prova-ho!](https://platform.openai.com/tokenizer).
[^attention]: Predir la paraula correcta és més complex que només tenir una [cadena de Markov](https://en.wikipedia.org/wiki/Markov_chain) amb les probabilitats entre tots els tokens, per exemple calia resoldre el problema de l'[atenció](https://en.wikipedia.org/wiki/Attention_Is_All_You_Need).
[^bullshitjobs]: En molts treballs moderns és fàcil sentir-se identificat amb l'operador de l'habitació xinesa, una sensació que David Graeber captura a _Bullshit Jobs: A Theory_.
[^transformer]: Bé, així és com OpenAI anomena l'API de GPT. En realitat s'anomenen _models de llenguatge extensos autoregressius_.
[^xines]: Si saps xinès, fes veure que l'experiment mental usa un altre idioma.
[^plato]: Plató, _Gòrgies_ a _Diàlegs_, vol. VIII, trad. Manuel Balasch, Bernat Metge, 1986.
[^kierkegaard]: Søren Kierkegaard, _En literair Anmeldelse_ a _Søren Kierkegaards Skrifter_, vol. 8, Søren Kierkegaard Forskningscentret, 2004.
[^heidegger]: Martin Heidegger, _Sein und zeit_, Max Niemeyer Verlag, 1927.
