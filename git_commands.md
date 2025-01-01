

## Git Pull with rebase

Sometimes we have an upstream that rebased/rewound a branch we're depending on. This can be a big problem -- causing messy conflicts for us if we're downstream.

The magic command is git pull --rebase

A normal git pull is, loosely speaking, something like this (we'll use a remote called origin and a branch called foo in all these examples):

# assume current checked out branch is "foo"
```
git fetch origin
git merge origin/foo
```
At first glance, you might think that a git pull --rebase does just this:
```
git fetch origin
git rebase origin/foo
```
But that will not help if the upstream rebase involved any "squashing" (meaning that the patch-ids of the commits changed, not just their order).

Which means git pull --rebase has to do a little bit more than that. Here's an explanation of what it does and how.

Let's say your starting point is this:

> a---b---c---d---e  (origin/foo) (also your local "foo")

Time passes, and you have made some commits on top of your own "foo":

> a---b---c---d---e---p---q---r (foo)

Meanwhile, in a fit of anti-social rage, the upstream maintainer has not only rebased his "foo", he even used a squash or two. His commit chain now looks like this:

> a---b+c---d+e---f  (origin/foo)

A git pull at this point would result in chaos. Even a git fetch; git rebase origin/foo would not cut it, because commits "b" and "c" on one side, and commit "b+c" on the other, would conflict. (And similarly with d, e, and d+e).

What git pull --rebase does, in this case, is:
```
git fetch origin
git rebase --onto origin/foo e foo
```
This gives you:

> a---b+c---d+e---f---p'---q'---r' (foo)

You may still get conflicts, but they will be genuine conflicts (between p/q/r and a/b+c/d+e/f), and not conflicts caused by b/c conflicting with b+c, etc.

 
# GitBash - Adding directory to newly created blank github repo 

1. From the GIT UI create a new repository
2. From the GitBash cmd line go to the project's root directory and run the following commmands
```
  git init
  git config --global core.autocrlf false
  git remote add origin https://github.com/sajivesukumara/RentBike.git
  git remote set-url origin https://<TOKEN>@github.com/sajivesukumara/RentBike.git
  git add .
  git commit -m "First commit"
  git push -u origin main
```
