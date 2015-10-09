# ido-clever-match

An alternative matcher for ido-mode.

## How it works

![clever](/clever.jpg)

The matcher ranks the input against each item by class and then
by some sub-metric within that class if applicable (length difference
between the two strings in the case of `substr`, the cumulative distance
of consecutive characters in the case of `flex`, whether the match was
case-sensitive or not, etc.).

The match classes are:

<dl>
  <dt><code>exact</code></dt>
  <dd>
    Exact matches score the highest and they require an exact string
    match.
  </dd>

  <dt><code>prefix</code></dt>
  <dd>
    Prefix matches score second highest. They are treated as a special
    case of <code>substring</code> matches and will always rank
    higher. This class differentiates between sub-matches by comparing
    the length of the input and each match: the closer the two numbers
    are, the higher the score will be.
  </dd>

  <dt><code>substring</code></dt>
  <dd>
    Substring matches score third highest. This class differentiates
    between sub-matches in the same way that prefix matches do with an
    additional check on the distance between the beginning of the
    string and the first occurrence of the text within that string:
    the further away the substring is from the beginning of the
    string, the lower it will score.
  </dd>

  <dt><code>flex</code></dt>
  <dd>
    Flex matches score lowest. This class differentiates between
    sub-matches by computing the cumulative distance of consecutive
    characters: the higher that distance is, the lower the score.
  </dd>
</dl>

### Gotchas

The matcher does not apply sub-metrics to strings longer than `512`
characters. That is, within a single class, all strings over `512`
characters are going to give the same score.

The matcher relies on heavy caching and might take up a lot of memory.

You might need to bump your GC threshold.

## Usage

To try it out simply run:

`M-x ido-clever-match-enable RET`

You can turn it off with:

`M-x ido-clever-match-disable RET`

To add it to your config:

```emacs-lisp
(require 'ido-clever-match)
(ido-clever-match-enable)
```
