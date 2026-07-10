use "files"
use "debug"
use "collections"
use "templates"

class DependencyRenderer is Renderer
  let _renderer: Renderer ref
  let _dir_path: FilePath val
  let _dep_renderers: Map[String val, Renderer ref] ref = _dep_renderers.create()

  new create(file_auth: FileAuth, path_str: String val, renderer: Renderer ref) =>
    _renderer = renderer
    _dir_path = FilePath(file_auth, Path.dir(path_str))
    add_base_deps(file_auth)
    add_raw_deps(file_auth, FilePath(file_auth, path_str)) // pass absolute path to compare
    add_templated_deps(file_auth)

  new without_base(file_auth: FileAuth, path_str: String val, renderer: Renderer ref) =>
    _renderer = renderer
    _dir_path = FilePath(file_auth, Path.dir(path_str))
    add_raw_deps(file_auth, FilePath(file_auth, path_str)) // pass absolute path to compare
    add_templated_deps(file_auth)

  fun ref add_base_deps(file_auth: FileAuth) =>
    // add all files in base assets as templated dependencies
    let base_deps = DirectoryReader.list_files(FilePath(file_auth, "pages/assets/"))
      .map[String val]({(p) => p.path})
      .map[String val]({(p) => try Path.rel(Path.cwd(), p)? else p end})
    for file_path in base_deps do
      _dep_renderers.insert(
        Path.base(file_path, false),
        DependencyRenderer.without_base(
          file_auth,
          file_path,
          TemplateRenderer(file_auth, file_path)
        )
      )
    end

  fun ref add_raw_deps(file_auth: FileAuth, self_path: FilePath val) =>
    // add other files in the same dir as raw dependencies
    let raw_deps = DirectoryReader.list_files(_dir_path)
      .map[String val]({(p) => p.path})
      .filter({(p) => p != self_path.path})
      .map[String val]({(p) => try Path.rel(Path.cwd(), p)? else p end})
    for file_path in raw_deps do
      _dep_renderers.insert(Path.base(file_path, false), RawRenderer(file_auth, file_path))
    end

  fun ref add_templated_deps(file_auth: FileAuth) =>
    // add all files one level down as templated dependencies
    let templated_deps = DirectoryReader.list_dirs(_dir_path)
      .flat_map[FilePath val]({(d) => DirectoryReader.list_files(d)})
      .map[String val]({(p) => p.path})
      .map[String val]({(p) => try Path.rel(Path.cwd(), p)? else p end})
    for file_path in templated_deps do
      _dep_renderers.insert(
        Path.base(file_path, false),
        DependencyRenderer(
          file_auth,
          file_path,
          TemplateRenderer(file_auth, file_path)
        )
      )
    end

  fun string(): String iso^ =>
    let res: String ref = recover String end
    res.append("DependencyRenderer")
    for (name, renderer) in _dep_renderers.pairs() do
      let child_str: String ref = renderer.string()
      child_str.replace("\t", "\t\t") // extra level of indent
      res.append("\n\t." + name + " -> " + child_str)
    end
    let child_str: String ref = _renderer.string()
    child_str.replace("\t", "\t\t") // extra level of indent
    res.add("\n\t-> " + child_str)

  fun ref load() =>
    for renderer in _dep_renderers.values() do
      renderer.load()
    end
    _renderer.load()
  fun render(values: TemplateValues box = TemplateValues): String val ? =>
    let values': TemplateValues ref = values.scope()
    for (name, renderer) in _dep_renderers.pairs() do
      let body = renderer.render(values)?
      values'.unescaped(name, body)
    end
    _renderer.render(values')?
