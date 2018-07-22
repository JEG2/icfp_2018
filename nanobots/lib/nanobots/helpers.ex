defmodule Nanobots.Helpers do

  def coordinate_in_model(model, c) do
    return MapSet.member?(model, c)
  end

  # model is map of coordinates
  def largest_line_from_coordinate(model, c = {cx, cy, cz}) do
    if !coordinate_in_model(model, c)
      return []
    end

  end

  def build_in_x(model, points = [first = {fx, fy, fz} | _rest]) do
    if !coordinate_in_model(model, {fx + 1, fy, fz})
      return points
    end
    build_in_x(model, [{fx + 1, fy, fz} | points])
  end

  def build_in_y(model, points = [first = {fx, fy, fz} | _rest]) do
    if !coordinate_in_model(model, {fx, fy + 1, fz})
      return points
    end
    build_in_y(model, [{fx, fy + 1, fz} | points])
  end

  def build_in_z(model, points = [first = {fx, fy, fz} | _rest]) do
    if !coordinate_in_model(model, {fx, fy, fz + 1})
      return points
    end
    build_in_z(model, [{fx, fy, fz + 1} | points])
  end



end
