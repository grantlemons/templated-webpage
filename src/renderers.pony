use "files"
use "debug"
use "templates"
use @system[I32](command: Pointer[U8] tag)

interface Renderer is Stringable
  fun ref load()
  fun render(values: TemplateValues box = TemplateValues): String val ?
 
class RawRenderer is Renderer
  let _file_auth: FileAuth
  let _path: String val
  var _file_content: (String val | None) = None

  new create(file_auth: FileAuth, path: String val) =>
    _file_auth = file_auth
    _path = path
    load()
  
  new unloaded(file_auth: FileAuth, path: String val) =>
    _file_auth = file_auth
    _path = path

  fun _read(path: String val): String val ? =>
    FileReader.read(FilePath(_file_auth, path))?

  fun string(): String iso^ => _path.string()
  fun ref load() => 
    try _file_content = _read(_path)? end

  fun render(
    values: TemplateValues box = TemplateValues
  ): String val ? => match _file_content
      | let content: String val => content
      | None => error
    end
  fun apply(): String val ? => render()?

class CodeRenderer is Renderer
  let _file_auth: FileAuth
  let _path: FilePath val
  let _output_path: FilePath val
  var _renderer: Renderer ref

  new create(file_auth: FileAuth, path: String val) =>
    _file_auth = file_auth
    _path = FilePath.create(_file_auth, path)

    _output_path = FilePath.create(_file_auth, path + ".html")
    _renderer = RawRenderer.unloaded(_file_auth, path + ".html")
    load()

  // TODO: behavior?
  fun generate(): None ? =>
    if not _path.exists() then error end
    if not _output_path.exists() then
      let command = "pygmentize -f html -O style=solarized-light -o " + _output_path.path + " " + _path.path
      if @system(command.cstring()) != 0 then error end
    end

  fun string(): String iso^ =>
    let child_str: String val = _renderer.string()
    "CodeRenderer -> " + child_str
  fun ref load() =>
    try
      generate()?
      _renderer.load()
    end
  fun render(values: TemplateValues box = TemplateValues): String val ? =>
    _renderer.render()?
  fun apply(): String val ? => render()?
