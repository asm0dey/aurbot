# aurbot

See [aurbot.github.io](https://aurbot.github.io).

## Adding packages

Please add only packages that you really use.

Until I get this part automated:

Before you add a package, determine its AUR dependencies, so that we are always aware of what needs to be build. You can do that by opening the respective AUR Info page (e.g. [aur.archlinux.org/packages/pyca](https://aur.archlinux.org/packages/pyca)), and look for links in the dependency section that point to the AUR instead of official repositories.

When you have determined all depencenies, please add them in reverse dependency order to the list. An Example:

`pyca` depends on `python-icalendar` from the AUR. Therefore You need to add the following lines to `.travis.yml`:

```yaml
  - python-icalendar # dependency of pyca
  - pyca
```

aurbot uses itself as a repository to speed up builds. Keeping this order makes sure, that we don't build packages multiple times. The comment `# dependency of pyca` is used to keep track of those dependencies for now. In the future a more intelligent solution that automatically determines the dependency graph and constructs the necessary build order should take care of this part.
