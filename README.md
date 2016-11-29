# ArchiveBundle

This is a super tiny archive installer for Elixir which contains a task to allow you to create an archive build including your Mix dependencies, as it's not supported in the standard library. There are cases where you might which to deal with JSON (for example), and you clearly don't want to write your own JSON parser or copy one into your project.

Although this enables you to include dependencies, please read the "Things To Know" section to understand the risks involved with doing so, and what you need to be concerned about. There are very valid reasons why this does not live in the Elixir standard library, and they should be understood. That said, I had a need for an archive containing my commonly used tasks and so here we are :)

## Setup

There are two ways to install this archive, either from a GitHub tag or by building it yourself:

```
# from latest GitHub release
$ mix archive.install https://github.com/zackehh/archive_bundle/archive/v1.0.0/archive-bundle-v1.0.0.ez

# building it yourself
$ git clone https://github.com/zackehh/archive_bundle
$ cd archive_bundle
$ mix do compile, archive.build, archive.install
```

Super easy to use, just run `mix archive.bundle` from inside your Mix project. It accepts the same arguments as `mix archive.build` except that we hijack `-i` internally for our own use.

## Things To Know

This archive uses a really trivial method to make this work; we copy everything into a temp directory and just point the archive builder to it - this means that all the code in your build directory is lumped together. Due to this, we'll throw an error if we detect something that will overwrite a file already copied, but sadly this means that you're out of luck with this archive. This is extremely unlikely to ever happen in the `ebin/` directory due to how developers structure their modules, but clashes in the `priv/` dir could very easily happen.

Also on the thread of clashes; the main reason that this does not exist in the standard library is down to archives being loaded into the VM. As such, multiple archives with different versions of the same dependency would clash and likely cause errors (not good). In spite of this I feel that a developer should be able to decide whether to take that risk or not, as creating your own bundles on a known system makes it very easy to avoid clashing. It's extremely visible (lots of warnings) in the case that there is a clash with a currently loaded module, so it should be easy to spot and resolve via an uninstall.

It should therefore be evident that you should likely not distribute archives created with this project to the public. If you do, please make sure to explain the risks appropriately and be responsible with what you include in your archive.
