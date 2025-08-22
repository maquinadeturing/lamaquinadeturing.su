---
title: "Philosophical notes on LLMs 1: form without content"
date:   2025-08-22T18:00:00+0200
image:  tinman.png
image_caption: |-
  The Tin Woodman with Alice and the Scarecrow, in [W. W. Denslow’s](https://en.wikipedia.org/wiki/W._W._Denslow) _Illustrations for the Wonderful Wizard of Oz_ (1900).
categories: Cybernetics
---

_What follows are some of notes trying to understand large language models with the help of different philosophical theories. I'm incredibly out of my element, so treat this text as experimental._

_As the title implies, more may follow._

[[toc]]

## Large language models are completion models

When a user writes a prompt, the chat bot responds with a reply. That is the foundation of the modern generative AI as most people know it. This interaction is useful because you can ask a question and get a response, or describe a task and get the result.

This gives the impression of intelligence, as the bot can do really complex tasks. From summarizing large texts at incredible speed, to maintaining an interesting conversation, programming an algorithm, or solving a difficult math problem. How did the companies that make these bots train them to do all of this?

The answer is not an incredibly dense program, but a clever trick: the bot just learned what is the most likely word to follow a sentence.

It really is more complex than this[^1][^2], but that's the essence. The bot looks at the prompt from the user, then adds the first word of the reply. Then another, and another. This is why they are also called _completion_ models.

In their core, chat bots only really know how to add one word. But they are _really good_ at it. Their whole world is adding just one word, the perfect one. After that, they do it again. This may generate several questions. How is it possible that coherent sentences, or even insightful ideas, are created this way, instead of nonsense? Well, the same way the game of [Consequences](https://en.wikipedia.org/wiki/Consequences_(game)) can create an [exquisite corpse](https://en.wikipedia.org/wiki/Exquisite_corpse), one word at a time.

## Form without content: Searle

Do large language models _know_ what they say? Do _we_ know what we say?

The most direct reference to chat bots is **John Searl's** [Chinese room](https://en.wikipedia.org/wiki/Chinese_room) argument. It goes like this: your job is to stay in a room, with a big book. Somebody throws in a card with some Chinese text, and you are expected to answer, also in Chinese. But you don't know Chinese! Luckily, the book is here to help you: just look for the rules that apply to the symbols you got, and follow them to get some equally enigmatic Chinese symbols as a response.[^3]

Sounds familiar? It is more or less what chat bots do. They have no idea what each symbol is, or what the whole sentence means. They don't even split sentences in words like we do![^1] They just follow rules. With this example Searl was arguing that artificial intelligence models are incapable of understanding.

In other words, chat bots just spill _bullshit._ This is different from lying, because that would require understanding. Hallucinations are one of the biggest problems that large language models have, because they are not designed around the concepts of _truth_ or _knowledge._ They are stochastic parrots, amazing bulshitters, professional Consequences players.

## Empty words: Plato, Aristotle

There is a rich European philosophical tradition of despising bullshit and nonsense, beginning with Socrates and Plato:

>Socrates: And the same holds of the relation of rhetoric to all the other arts; the rhetorician need not know the truth about things; he has only to discover some way of persuading the ignorant that he has more knowledge than those who know?
>--- _Gorgias_ by Plato, 380 BC ([trans.](https://en.wikisource.org/wiki/Sophist_(Jowett)) by Benjamin Jowett).

To **Plato,** the appearance of wisdom without actual knowledge is just a "knack of flattery", pretending rather than being. And boy, would he and Socrates have hated chat bots! The ultimate rhetoricians, words completely disconnected from actual knowledge.

**Aristotle** also considers _logos_ -reasoning- the structure of an argument, while _pathos_ and _ethos_ add emotional persuasion and credibility. In this context, any speech without _logos_, made of chains of words connected by probability, would fall apart. And indeed it does, if you push a chat bot a little bit.

## Chatter: Kierkegaard, Heidegger

Such stream of words devoid of meaning -both in the sense of knowledge and intention- would certainly irritate certain no-bullshit philosophers. For **Søren Kierkegaard,** the amount of _snak_ -chatter- was already unbearable in the XIX century:

>What is talkativeness? It is the result of doing away with the vital distinction between talking and keeping silent. Only someone who knows how to remain essentially silent can really talk —and act essentially. Silence is the essence of inwardness, of the inner life. Mere gossip anticipates real talk, and to express what is still in thought weakens action by forestalling it.
>
>--- _The present age_ by S. Kierkegaard, 1846.

For Kierkegaard, silence, inwardness and passion are the essence of an authentic existence. Large language models, with their endless chatter of empty words and total lack of agency are the extreme opposite. There is no inner life, there is no room for action.

Chatter was also despised by **Martin Heidegger.** But we need to better understand his ideas first, which are notoriously slippery. He had a curious theory of how humans perceive the world. For instance, how a tree can give us shadow or how a cookie is sweet food to be eaten is the primordial relation we have with these objects, while their shape, color or size are derivative properties used by the rational mind. Not only that, but focusing on the theory will deprive us from this practical knowledge.

After all, why _learning about an object_ when you can _experience an action_? Theory will give you second-hand knowledge, mediated by others, while practice will give you an unfiltered, authentic experience. This is what Heidegger considers _authentic,_ concerned with the world.

Unfortunately, we live constantly distracted, fascinated by the world of _others,_ by their second-hand _idle talk._ After all, we are social animals and it is not possible to experience everything directly, we have to learn a whole lot. But this knowledge, once it starts circulating, is dettached, untrustworthy, superficial -in a practical sense- and it may distract us from the primordial experience.

>What is said-in-the-talk as such, spreads in wider circles and takes on an authoritative character. Things are so because one says so. Idle talk is constituted by just such gossiping and passing the word along -a process by which its initial lack of grounds to stand on becomes aggravated to complete groundlessness. And indeed this idle talk is not confined to vocal gossip, but even spreads to what we write, where it takes the form of 'scribbling'. In this latter case the gossip is not based so much upon hearsay.
It feeds upon superficial reading . The average understanding of the reader will never be able to decide what has been drawn from primordial sources with a struggle and how much is just gossip.
>
>--- _Being and Time_ by Martin Heidegger, 1962 (trans. John Macquarrie and Edward Robinson, p. 212, SZ 169).

This is why, from the point of view of Heidegger, large language models would be machines of pure _idle talk._ Their third-hand words are detached from the world, completely unathentic. The more we use a chat bot, the more it prevents us from experiencing the world directly.

## Notes

[^1]: Large language models use tokens, which are symbols smaller than words, for [complicated reasons](https://en.wikipedia.org/wiki/Large_language_model#Tokenization). For instance, this is how ChatGPT 4 reads a sentence: "A| spect|re| is| haunting| Europe| —| the| spect|re| of| commun|ism|.". [Try it!](https://platform.openai.com/tokenizer).
[^2]: Predicting the right word is more complex than just having a [Markov chain](https://en.wikipedia.org/wiki/Markov_chain) with the probabilities between all tokens, for instance it required solving the [attention](https://en.wikipedia.org/wiki/Attention_Is_All_You_Need) problem.
[^3]: In many modern jobs it is easy to relate to the Chineese room operator, a feeling that David Graeber captures in _Bullshit Jobs: A Theory_.
