// data structures for storing 4D volumes

class Cell {
  Face[] faces;
  ArrayList<FloatMatrix> vertices;
  FloatMatrix normal;
  color cellColor;
  int cellNum;
  boolean visible;

  Cell(ArrayList<Face> theseFaces) {
    this(theseFaces, -1, color(255, 255, 255));
  }
  Cell(ArrayList<Face> theseFaces, int number, color thisColor) {
    vertices = new ArrayList<FloatMatrix>();
    normal = new FloatMatrix(4);
    faces = new Face[theseFaces.size()];
    cellNum = number;
    Iterator itr = theseFaces.iterator();
    int i = 0;
    while (itr.hasNext ()) {
      Face face = (Face) itr.next();
      faces[i] = face;
      vertices.addAll(face.vertices);
      i++;
    }
    cellColor = thisColor;
    visible = true;
  }
}

class Face {
  ArrayList<FloatMatrix> vertices;
  ArrayList<Edge> edges;
  ArrayList<Integer> numberedVertices;
  int faceNum;
  color faceColor;


  Face(Collection theseVertices) {
    this(theseVertices, color(255, 255, 255));
  }
  Face(Collection theseVertices, Collection numVerts) {
    this(theseVertices, numVerts, -1, color(255, 255, 255));
  }
  Face(Collection theseVertices, color thisColor) {
    vertices = new ArrayList<FloatMatrix>();
    vertices.addAll(theseVertices);
    numberedVertices = new ArrayList<Integer>();
    for (int i =0; i < vertices.size(); i ++) {
      numberedVertices.add(i);
    }
    faceNum = -1;
    faceColor = thisColor;
  }
  Face(Collection theseVertices, Collection numVerts, int num) {
    vertices = new ArrayList<FloatMatrix>();
    vertices.addAll(theseVertices);
    numberedVertices = new ArrayList<Integer>();
    numberedVertices.addAll(numVerts);
    faceNum = num;
  }

  Face(Collection theseVertices, Collection numVerts, int num, color thisColor) {
    vertices = new ArrayList<FloatMatrix>();
    vertices.addAll(theseVertices);
    numberedVertices = new ArrayList<Integer>();
    numberedVertices.addAll(numVerts);
    faceColor = thisColor;
    faceNum = num;
  }
}

class Edge {
  ArrayList<FloatMatrix> vertices;

  Edge(FloatMatrix _start, FloatMatrix _end) {
    vertices = new ArrayList<FloatMatrix>();
    vertices.add(_start);
    vertices.add(_end);
  }
}

class Face3 {
  ArrayList<FloatMatrix> vertices;
  ArrayList<FloatMatrix> oldVertices;
  ArrayList<FloatMatrix> normal3D;
  ArrayList colors;
  color faceColor;
  ArrayList<Integer> numberedVertices;
  int faceNum;
  boolean parentCellVisible;

  Face3(Collection verts, Collection oldVerts, Collection numVerts, int numOfFaces, color thisColor, ArrayList theseColors, boolean visible) {
    vertices = new ArrayList<FloatMatrix>();
    vertices.addAll(verts);
    oldVertices = new ArrayList<FloatMatrix>();
    oldVertices.addAll(oldVerts);
    faceNum = numOfFaces;
    colors = new ArrayList();
    colors.addAll(theseColors);
    numberedVertices = new ArrayList<Integer>();
    numberedVertices.addAll(numVerts);
    faceColor = thisColor;
    parentCellVisible = visible;
  }
}

class Label {
  String labelText;
  float x, y;
  color labelColor;

  Label(String _text, float _x, float _y) {
    this(_text, _x, _y, color(255));
  }
  Label(String _text, float _x, float _y, color thisColor) {
    labelText = _text;
    x = _x;
    y = _y;
    labelColor = thisColor;
  }

  void draw() {
    text(labelText, x, y, -1);
  }
}

