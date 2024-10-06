---
title: "Git rebase doesn't do what you think"
date:   2024-10-05 20:00:00 +0200
image:  branches.jpg
image_caption: |-
  [Miniature from a 12th-century Medical and Herbal Collection](https://publicdomainreview.org/collection/miniatures-from-a-12th-century-medical-and-herbal-collection/) once owned by the monastery at Ourscamps just north of Paris, and now in the collection at the British Library (BL Sloane 1975).
---

As [xkcd says](https://xkcd.com/1597/), Git is an awesome tool, but if something goes wrong just delete everything and download a fresh copy.

One of these "oops" moments is `git rebase`. The cool brother of `git merge` is as powerful as misunderstood. I am writing this post because sometimes it surprises me that so many people will stumble upon common rebasing pitfalls.

What I want to explain in this post is the following:

{% toc maxdepth:2 %}

## 1. What people think rebasing does

Git is like a tree, with a common trunk like `main` and branches like `develop`:

<pre class="mermaid">
%%{init: { 'theme': 'base' } }%%
gitGraph
    commit id: "1"
    commit id: "2"
    branch develop
    checkout develop
    commit id: "5"
    commit id: "6"
    checkout main
    commit id: "3"
    commit id: "4"
</pre>

If we execute:

```bash
git switch develop
git rebase main
```

Then commits 5 and 6 will be moved (if there are no conflicts) to the tip of `main` like this:

<pre class="mermaid">
%%{init: { 'theme': 'base' } }%%
gitGraph
    commit id: "1"
    commit id: "2"
    commit id: "3"
    commit id: "4"
    branch develop
    checkout develop
    commit id: "5"
    commit id: "6"
</pre>

It appears as if we took commits 5 and 6 and dragged and dropped them on top of commit 4. Simple, right? Well, not exactly.

## 2. What rebasing actually does

The impression users get from rebasing is that commits are "moved". We wanted branch `develop` to be at the tip of `main`. But how does Git know which commits to move?

Intuitively, we know that we wanted commits 5 and 6 to be moved from commit 2 to commit 4. So let's give these two commits a name:

* Commit 2 is the *common ancestor*.
* Commit 4 is the *merge base*.

When doing a rebase, Git first calculates the common ancestor of the source branch and the target branch (commit 2). Then it selects all the commits from the common ancestor to the tip of the source branch and applies them to the merge base.

In other words, the previous commands are equivalent to:

```bash
git branch -d develop
git switch main
git checkout -b develop
git cherry-pick 5
git cherry-pick 6
```

It is important here to understand these two ideas about rebasing:
1. Commits are not moved, but re-applied.
2. Rebasing is done from a common ancestor to a merge base.

The first point is the cause of a common pitfall that makes people fear rebasing. The second is the key to avoiding it.

## 3. The common pitfall when rebasing

In collaborative teams, the following situation is very common: a feature branch `bar` depends on a previous feature `foo`. Meanwhile, `main` has continued to grow (commits 7 and 8). When feature `foo` is finally rebased on top of `main`, there is a conflict between its commits and the new commits in `main`:


<pre class="mermaid">
%%{init: { 'theme': 'base' } }%%
gitGraph
    commit id: "1"
    commit id: "2"
    branch feature/foo
    checkout feature/foo
    commit id: "3" type: REVERSE
    commit id: "4" type: REVERSE
    branch feature/bar
    checkout feature/bar
    commit id: "5"
    commit id: "6"
    checkout main
    commit id: "7" type: HIGHLIGHT
    commit id: "8" type: HIGHLIGHT
</pre>

Inevitably, these conflicts have to be resolved. This usually causes the rebased commits to be different than the original:

<pre class="mermaid">
%%{init: { 'theme': 'base', 'themeVariables': {'git0': '#ffcb5d', 'git1': '#77a3ff' } } }%%
gitGraph
    commit id: "1"
    commit id: "2"
    branch feature/bar
    checkout feature/bar
    commit id: "3" type: REVERSE
    commit id: "4" type: REVERSE
    commit id: "5"
    commit id: "6"
    checkout main
    commit id: "7"
    commit id: "8"
    commit id: "3'" type: HIGHLIGHT
    commit id: "4'" type: HIGHLIGHT
</pre>

That is, commits 3' and 4' are now different than the original commits 3 and 4. They *look the same* to a human, because usually their title and description will be the same, but their changeset is different. And this is the source of our pain.

Imagine that you are the author of feature `bar`. From your point of view, feature `foo` and its commits 3 and 4 are now on top of `main`, so you should be able to rebase your branch without any conflicts.

Based on what we learned, we now know that:

```bash
git switch feature/bar
git rebase main
```

Will calculate the common ancestor between `bar` and `main` (commit 2) and try to re-apply commits 3, 4, 5 and 6 on top of commit 4'. Git is very smart, so in an ideal world it will detect duplicated commits, like 3 and 4, and skip them, so only 5 and 6 will be re-applied.

However, commits 3' and 4' are now too different, and Git complains, and you didn't expect that and you hate rebasing.

Let's see what can be done about this.

## 4. Why rebasing onto is what you actually wanted

In the previous example, the owner of feature `bar` doesn't want to re-apply commits 3, 4, only 5 and 6. So how to tell Git to skip the old commits 3 and 4?

The key is to provide a different common ancestor. Instead of:

```bash
git rebase main
```

What we can do is:

```bash
git rebase 4 --onto main
```

With this command, what we are telling Git is:

1. Use commit 4 as the common ancestor.
2. Use `main` as the merge base.

(Important note here: the common ancestor is not included in the rebase.)

Git, knowing this, will only select the commits between the common ancestor (commit 4) and the source branch: commits 5 and 6. When re-applying them on top of the tip of main (commit 4'), they should be fine most of the time.

<pre class="mermaid">
%%{init: { 'theme': 'base' } }%%
gitGraph
    commit id: "1"
    commit id: "2"
    commit id: "7"
    commit id: "8"
    commit id: "3'" type: HIGHLIGHT
    commit id: "4'" type: HIGHLIGHT
    commit id: "5" type: HIGHLIGHT
    commit id: "6" type: HIGHLIGHT
</pre>

Before finishing, a few notes. First, before knowing about `git rebase --onto` my mental rebasing model was *moving branches*, with no way to limit the string of commits attached to them. I guess that many people feel like this about Git. After learning about it, and better understanding what rebasing does, how my brain works now is akin to *selecting a list of commits* and *dragging and dropping* them onto another place. Literally this is what I would like Git tools to offer me: as if it was a PowerPoint slide, I would like commits to be like text boxes to be selected, edited, dragged and dropped, deleted...

This also has important consequences when using `git rebase --interactive`, because when we want to apply modifications to the rebased commits it is important to understand how Git selects that list of commits. If you want to better understand how the common ancestor works, you can try `git rebase -i main` and see that it will show commits 3, 4, 5 and 6, while `git rebase -i 4 --onto main` will show commits 5 and 6.

Another important difference between `git rebase` and `git rebase --onto`: when specifying the common ancestor, that commit will not always be nicely tagged with a branch. So do not be afraid of using the hash of the commit as the common ancestor.

And a disclaimer: Git and rebasing is even more complicated and I made some intentional and unintentional simplifications in this post, but in general I find that this mental model of Git works quite well.

In conclusion, if we want to move the commits between branch `base` and `source`, and apply them to `target`, the command is:

```bash
git switch source
git rebase base --onto target
```
