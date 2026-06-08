# How to Use Debuggers With Zammad

There is not much explanation needed on how to code. But there always comes the time where you get stuck. We made
pretty good experience with the following tools in such situations:

- `pry`
- `pry-remote`
- `pry-rescue`

## `forego` + debuggers = 🤦

If you're used to inserting debugging breakpoints into your code (_e.g.,_ with Pry), `forego` may throw you
for a loop — since it manages the output of multiple processes,
[**your debugger prompt will appear briefly on the screen and then fly past it, along with the STDOUT of any other
processes `forego` is overseeing**](https://github.com/ddollar/foreman/issues/58).

Instead, use a remote debugger like [pry-remote](https://github.com/mon-ouie/pry-remote).
