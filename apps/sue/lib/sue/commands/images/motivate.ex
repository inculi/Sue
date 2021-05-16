defmodule Sue.Commands.Images.Motivate do
  alias Sue.Utils

  import Mogrify

  def top_text(text, img, path) do
    img
    |> custom("size", "600")
    |> custom("background", "black")
    |> custom("font", "Times")
    |> custom("gravity", "center")
    |> custom("pointsize", "56")
    |> custom("pango", ~s(<span foreground="white">#{text}</span>))
    |> create(path: path)
  end

  # TODO: Remove when I figure out how to get extent working...
  def middle_spacing(img, path, height \\ 10) when is_integer(height) do
    img
    |> custom("size", "600x#{height}")
    |> canvas("black")
    |> custom("fill", "black")
    |> create(path: path)
  end

  @spec bottom_text(any, %{:operations => list, optional(any) => any}, any) :: %{
          :dirty => %{},
          :operations => [],
          optional(any) => any
        }
  def bottom_text(text, img, path) do
    img
    |> custom("size", "600")
    |> custom("background", "black")
    |> custom("font", "Times")
    |> custom("gravity", "center")
    |> custom("pointsize", "28")
    |> custom("pango", ~s(<span foreground="white">#{text}</span>))
    |> create(path: path)
  end

  def borders(in_img_path, out_img_path) do
    # we will be saving changes to the file in-place
    File.cp!(in_img_path, out_img_path)

    open(in_img_path)
    |> custom("scale", "500")
    |> custom("bordercolor", "black")
    |> custom("border", "5")
    |> custom("bordercolor", "white")
    |> custom("border", "3")
    |> custom("mattecolor", "black")
    |> custom("frame", "50x50")
    |> custom("geometry", "600")
    |> save(path: out_img_path)
  end

  def append(img, pattern, path) do
    img
    |> custom("append", pattern)
    |> create(path: path)
  end

  def run(imagepath, top_text, bot_text) do
    tmp_file_prefix = Utils.tmp_file_name("")
    workingpath = System.tmp_dir!()

    borders(imagepath, Path.join([workingpath, tmp_file_prefix <> "1.png"]))

    top_text(
      top_text,
      %Mogrify.Image{path: tmp_file_prefix <> "2.png", ext: "png"},
      workingpath
    )

    _bot_img =
      if bot_text |> String.trim() |> String.length() > 0 do
        middle_spacing(%Mogrify.Image{path: tmp_file_prefix <> "3.png", ext: "png"}, workingpath)

        bottom_text(
          bot_text,
          %Mogrify.Image{path: tmp_file_prefix <> "4.png", ext: "png"},
          workingpath
        )
      else
      end

    middle_spacing(%Mogrify.Image{path: tmp_file_prefix <> "5.png", ext: "png"}, workingpath, 20)

    append(
      %Mogrify.Image{path: tmp_file_prefix <> "out.png", ext: "png"},
      Path.join([workingpath, tmp_file_prefix <> "*.png"]),
      workingpath
    )

    Path.join([workingpath, tmp_file_prefix <> "out.png"])
  end
end
