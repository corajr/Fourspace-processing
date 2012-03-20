color[] colorRandom = new color[] {
  color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0), color(255, 0, 255), color(0, 255, 255)
};

// or, uncomment for all white
// color[] colorRandom = new color[]{color(255,255,255)};

Cell[] genAxes() {  // generate a basic set of 4D axes
  ArrayList<Face> faces = new ArrayList<Face>();
  Cell[] result = new Cell[1];
  FloatMatrix[] verts = new FloatMatrix[] {
    new FloatMatrix(new float[] {
      0, 0, 0, 0
    }
    ), 
    new FloatMatrix(new float[] {
      1, 0, 0, 0
    }
    ), 
    new FloatMatrix(new float[] {
      0, 1, 0, 0
    }
    ), 
    new FloatMatrix(new float[] {
      0, 0, 1, 0
    }
    ), 
    new FloatMatrix(new float[] {
      0, 0, 0, 1
    }
    )
    };

  color[] colors = new color[] {
    color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 255)
  };

  for (int i = 1; i < 5; i++) { 
    ArrayList<FloatMatrix> edge = new ArrayList<FloatMatrix>();
    edge.add(verts[0]);
    edge.add(verts[i]);
    faces.add(new Face(edge, colors[i-1]));
  }
  result[0] = new Cell(faces);
  return result;
}

Cell[] genFromVEFCfile(String filename) {    // load from comma-separated VEFC data file
  ArrayList<FloatMatrix> vertices = new ArrayList<FloatMatrix>();
  ArrayList<Edge> edges = new ArrayList<Edge>();
  ArrayList<Face> faces = new ArrayList<Face>();
  ArrayList<Cell> cells = new ArrayList<Cell>();

  String lines[] = loadStrings(filename);
  String mode = "V"; // V(ertices), E(dges), F(aces), or C(ells)
  int numOfFaces = 0;
  int numOfCells = 0;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].length() < 3) {
      mode = trim(lines[i]);
      continue;
    }   
    String colorOptions[] = split(lines[i], "; "); // if color has been specified, the line will have a semicolon
    String components[] = split(colorOptions[0], ", ");

    if (mode.equals("V")) {      // vertices
      float[] thisCoords = new float[4];
      thisCoords[0] = float(components[0]);
      thisCoords[1] = float(components[1]);
      thisCoords[2] = float(components[2]);
      thisCoords[3] = float(components[3]);
      vertices.add(new FloatMatrix(thisCoords));
    }

    if (mode.equals("E")) {    //  edges (currently these are not used for anything...)
      edges.add(new Edge(vertices.get(int(components[0])), vertices.get(int(components[1]))));
    }
    if (mode.equals("F")) {    // faces
      ArrayList<FloatMatrix> theseVertices = new ArrayList<FloatMatrix>();
      ArrayList<Integer> numVerts = new ArrayList<Integer>();

      for (int j = 1; j < components.length; j++) {
        numVerts.add((Integer) int(components[j]));
        theseVertices.add(vertices.get(int(components[j])));
      }

      //    used to set colors by hex values, e.g. "0, 1, 2; FF336699" (AARRGGBB)
      color thisColor = colorRandom[numOfFaces % colorRandom.length];
      if (colorOptions.length > 1) {
        thisColor = color(unhex(colorOptions[1]));
      }


      faces.add(new Face(theseVertices, numVerts, numOfFaces, thisColor));
      numOfFaces++;
    }

    if (mode.equals("C")) {  // cells
      ArrayList<Face> theseFaces = new ArrayList<Face>();
      for (int j = 0; j < components.length; j++) {
        theseFaces.add(faces.get(int(components[j])));
      }
      color thisColor = colorRandom[numOfCells % colorRandom.length];
      if (colorOptions.length > 1) {
        thisColor = color(unhex(colorOptions[1]));
      }
      Cell thisCell = new Cell(theseFaces, numOfCells, thisColor);
      cells.add(thisCell);
      for (Face face: thisCell.faces) {
        face.faceColor = thisCell.cellColor;
      } 
      numOfCells++;
    }
  }
  if (cells.size() == 0) cells.add(new Cell(faces));

  Cell[] result = new Cell[cells.size()];
  for (int j = 0; j < cells.size(); j++) {
    result[j] = (Cell) cells.get(j);
  }

  // display stats
  //  println(str(cells.size()) + " cells, " + str(faces.size()) + " faces, "+ str(edges.size()) + " edges, " + str(vertices.size()) + " vertices");
  return result;
}

