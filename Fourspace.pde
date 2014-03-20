/**
 * Fourspace 
 * by Chris Johnson-Roberson
 * first working March 21, 2012
 *
 * projection algorithm from "Four-Space Visualization of 4D Objects" <http://steve.hollasch.net/thesis/> (Hollasch 1991)
 * native matrix math routines from <http://jblas.org>
 *
 */

import damkjer.ocd.*;
import processing.opengl.*;
import javax.media.opengl.*;
import java.util.*;
import org.jblas.*;

PGraphicsOpenGL pgl;
GL2 gl;

ArrayList faces, labels;
Cell[] cells;
float S, T, scale;
float[] from, from3D, cameraFrom, to, up, over, aimAt;
float[] attitude = {
  0.0, 0.0, 0.0
};
FloatMatrix V, Va, Vb, Vc, Wa, Wb, Wc, Wd;
FloatMatrix fromColumnVector, fromRowVector, fromColumnVector4D, fromRowVector4D;
FloatMatrix toMatrix, upMatrix, overMatrix, transform, transform4D, pt1, pt2;
FloatMatrix xwMatrix, ywMatrix, zwMatrix;
color depthCue = color(255, 255, 255);
float centerX, centerY, viewAngle, defaultTheta, lastXWtheta, lastYWtheta, lastZWtheta, radius = 1.0;
float interocularAngle = -0.03509;
int steps = 10;
String proj_type;
Camera cam1, cam2, camAxes;
int opacity = 0x44FFFFFF;

String modelName = "8-cell (hypercube)";

boolean camsInitialized = false;
boolean stereo = false;
boolean panning = false;
boolean facesActive = true, normalsActive = false, axesActive = false;
boolean labelsActive = false, namesActive = false;
boolean faceLabels = true, cellLabels = false, vertexLabels = false, vertexCoordLabels = false;
boolean fps = false, helpActive = true;
boolean lockTo4DViewpoint = false;
boolean depthCueing = true, hiddenVolumeRemoval = false;
boolean rotXW = false, rotYW = false, rotZW = false;

String[] helpText = new String[] { 
  "h or ?: show/hide help", 
  "mouse: drag to rotate, alt/cmd-click to pan, mousewheel to zoom",
  "1-7: choose geometry", 
  "x, y, z: rotate counterclockwise in XW, YW, ZW plane", "X, Y, Z: rotate clockwise", 
  "r: reset", 
  "k: lock to 4D viewpoint",
  "i: show/hide names", 
  "a: show/hide axes", "f: show/hide faces", "l: show/hide labels", "n: show/hide normals", 
  "p: parallel/perspective projection", 
  "v: show/hide hidden volumes", "d: depth cueing on/off", 
  ",: increase opacity", ".: decrease opacity", 
  "<space>: stereo on/off", "=: increase interocular angle", "-: decrease interocular angle",
  "ESC: exit"
};


void setup() {
  size(displayWidth, displayHeight, OPENGL);
  
  pgl = (PGraphicsOpenGL) g;

  proj_type = "PERSPECTIVE";
  centerX = width/2.0;
  centerY = height/2.0;
  viewAngle = radians(45);
  labels = new ArrayList<Label>();

  lastXWtheta = 0;
  lastYWtheta = 0;
  lastZWtheta = 0;
  scale = 1.0;
  S = 1.0;
  from = new float[] {    // 4D viewpoint
    1, 4, 0, 0
  };

  cameraFrom = new float[3];
  cameraFrom[0] = from[0];
  cameraFrom[1] = from[1];
  cameraFrom[2] = from[2];
  to = new float[] {    // 4D focus point
    0, 0, 0, 0
  };
  aimAt = new float[] {  // 3D camera focus
    0, 0, 0
  };
  up = new float[] { 
    0, 1, 0, 0
  };
  over = new float[] {
    0, 0, 1, 0
  };
  fromColumnVector4D = new FloatMatrix(from);
  fromRowVector4D = fromColumnVector4D.dup().reshape(1, 4);


  toMatrix = new FloatMatrix(to).dup();
  upMatrix = new FloatMatrix(up).dup();
  overMatrix = new FloatMatrix(over).dup();

  faces = new ArrayList<Face3>();
  cells = genFromVEFCfile("data/8cell_vefc.txt");    // default to 8-cell (hypercube)

  transform4D = Calc4Matrix(fromColumnVector4D, toMatrix, upMatrix, overMatrix);
  project4Dcells();
  cam1 = new Camera(this, cameraFrom[0], cameraFrom[1], cameraFrom[2], aimAt[0], aimAt[1], aimAt[2], radians(45), (float) 1.0*width/height, 0.001, 20);
  cam2 = new Camera(this, cameraFrom[0], cameraFrom[1], cameraFrom[2], aimAt[0], aimAt[1], aimAt[2], radians(45), (float) 1.0*width/height, 0.001, 20);
  camAxes = new Camera(this, cameraFrom[0], cameraFrom[1], cameraFrom[2], aimAt[0], aimAt[1], aimAt[2], radians(45), (float) 1.0*width/height, 0.001, 20);
  camsInitialized = true;

  addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
    }
  }
  );
}

void draw() {
  background(0);
  noLights();
  stroke(255);

  gl = ((PJOGL) beginPGL()).gl.getGL2();

  if (labelsActive || helpActive || namesActive) labels.clear();
  if (stereo) {
    gl.glViewport(0, 0, width/2, height);
  }
  cam1.feed();
  drawCells();

  if (stereo) {
    gl.glViewport(width/2, 0, width/2, height); 
    cam2.feed();
    drawCells();
  }

  hint(DISABLE_DEPTH_TEST);
  if (labelsActive || helpActive || namesActive) drawLabels();
  if (axesActive) project4Daxes();

  if (rotXW || rotYW || rotZW) {
    if (rotXW) rotateXW(defaultTheta);
    if (rotYW) rotateYW(defaultTheta);
    if (rotZW) rotateZW(defaultTheta);

    transform4D = Calc4Matrix(fromColumnVector4D, toMatrix, upMatrix, overMatrix);

    if (lockTo4DViewpoint) {
      FloatMatrix temp = project4Dvector(fromColumnVector4D);
      float pos[] = cam1.position();
      float newX = pos[0] + (temp.get(0) - pos[0])/60;
      float newY = pos[1] + (temp.get(1) - pos[1])/60;
      float newZ = pos[2] + (temp.get(2) - pos[2])/60;

      cam1.jump(newX, newY, newZ);
      if (stereo) {
        cam2.jump(newX, newY, newZ);
        cam1.circle(interocularAngle);
        cam2.circle(-interocularAngle);
      }
    }
    project4Dcells();
  }
  endPGL();
}

void drawCells() {
  if (normalsActive) {
    for (Cell cell : cells) {
      drawCellNormal(cell);
    }
  }
  if (cells.length > 1) {
    for (Cell cell : cells) {
      if (labelsActive && cellLabels) addLabels(cell);
      if (cell.visible) {
        for (Face face: cell.faces) {
          face.faceColor = cell.cellColor;
        }
      }
    }
  }
  int i = 0;
  radius = 1.0;
  Iterator faceItr = faces.iterator();
  while (faceItr.hasNext ()) {
    Face3 face = (Face3) faceItr.next();
    if (!face.parentCellVisible && hiddenVolumeRemoval) continue;
    if (facesActive && !depthCueing) fill(opacity & face.faceColor);
    else noFill();
    beginShape();
    ListIterator itr = face.vertices.listIterator();
    while (itr.hasNext ()) {
      FloatMatrix vert = (FloatMatrix) itr.next();
      int thisI = itr.previousIndex();
      int nextI = itr.nextIndex();
      if (depthCueing) {
        if (facesActive) fill(opacity & (color)(Integer) face.colors.get(thisI));
        stroke((color)(Integer) face.colors.get(thisI));
      }
      else {
        stroke(face.faceColor);
      }
      vertex(vert.get(0), vert.get(1), vert.get(2));
    }
    endShape(CLOSE);
    i++;
    if (labelsActive) addLabels(face);
    //    if (normalsActive) drawCellNormal(face.vertices, face.normal);
  }
}


void cameraRecenter() {
  if (camsInitialized) {
    cam1.aim(aimAt[0], aimAt[1], aimAt[2]);
    cam2.aim(aimAt[0], aimAt[1], aimAt[2]);
  }
}

void project4Daxes() {
  String p = proj_type;
  proj_type = "PARALLEL";
  gl.glViewport(width-80, height - 80, 80, 80);
  camAxes.feed();
  float pos[] = cam1.position();
  camAxes.jump(pos[0], pos[1], pos[2]);
  FloatMatrix temp = project4Dvector(toMatrix);
  camAxes.aim(temp.get(0), temp.get(1), temp.get(2));

  for (Cell cell : genAxes()) {
    for (Face face : cell.faces) {
      Iterator itr = face.vertices.iterator();
      stroke(face.faceColor);
      beginShape(LINES);
      while (itr.hasNext ()) {
        FloatMatrix vert = (FloatMatrix) itr.next();
        vert = project4Dvector(vert);
        vertex(vert.get(0), vert.get(1), vert.get(2));
      }
      endShape();
    }
  }
  proj_type = p;
}

FloatMatrix project4Dvector(FloatMatrix vec) {
  FloatMatrix newVec = new FloatMatrix(3);
  if (proj_type == "PARALLEL") S = 1.0; // kludge; should be 1/radius around to-point
  else T = 1 / tan(viewAngle/2);
  pt1 = vec.dup().reshape(1, 4).sub(fromRowVector4D).mmul(transform4D).reshape(4, 1).sub(fromColumnVector4D);
  if (proj_type == "PERSPECTIVE") {
    float w = pt1.dot(Wd);
    if (pt1.norm2() > radius) radius = pt1.norm2();
    depthCue = color((int) ((w/radius)*256));
    S = T / w;
  }
  newVec.put(0, S * pt1.dot(Wa));
  newVec.put(1, S * pt1.dot(Wb));
  newVec.put(2, S * pt1.dot(Wc));
  return newVec;
}


void project4Dcells() {
  faces.clear();
  if (proj_type == "PARALLEL") S = 1.0; // kludge; should be 1/radius around to-point
  else T = 1 / tan(viewAngle/2);

  pt1 = toMatrix.dup().reshape(1, 4).sub(fromRowVector4D).mmul(transform4D).reshape(4, 1).sub(fromColumnVector4D);
  if (proj_type == "PERSPECTIVE") {
    S = T / pt1.dot(Wd);
  }
  aimAt[0] = S * pt1.dot(Wa);
  aimAt[1] = S * pt1.dot(Wb);
  aimAt[2] = S * pt1.dot(Wc);

  cameraRecenter();
  for (Cell cell : cells) {
    cell.normal = cellNormal(cell);
    if (cells.length > 1) cellIsVisible(cell);
    else cell.visible = true;
    for (Face face : cell.faces) {
      ArrayList<FloatMatrix> projectedVerts = new ArrayList<FloatMatrix>();
      ArrayList theseColors = new ArrayList();
      Iterator vitr = face.vertices.iterator();
      while (vitr.hasNext ()) {
        FloatMatrix vert = (FloatMatrix) vitr.next();
        projectedVerts.add(project4Dvector(vert));
        if (proj_type == "PERSPECTIVE") theseColors.add(blendColor(depthCue, face.faceColor, MULTIPLY));
        else theseColors.add(face.faceColor);
      }
      faces.add(new Face3(projectedVerts, face.vertices, face.numberedVertices, face.faceNum, face.faceColor, theseColors, cell.visible));
    }
  }
}




void keyPressed() {
  if (key == '-') {
    interocularAngle -= 0.01;
    cam1.circle(0.01);
    cam2.circle(-0.01);
  }
  if (key == '=') {
    interocularAngle += 0.01;
    cam1.circle(-0.01);
    cam2.circle(0.01);
  }

//  if (key == '-' || key == '=') {
//    println(interocularAngle);
//  }


  if (key == 'a') {
    axesActive = !axesActive;
  }
  if (key == 'v') {
    hiddenVolumeRemoval = !hiddenVolumeRemoval;
  }
  if (key == 'd') {
    depthCueing = !depthCueing;
  }


  if (key == ',') {
    int currentOpacity = ((opacity >> 24) & 0xFF);
    currentOpacity = constrain(currentOpacity - 16, 1, 255);
    opacity = currentOpacity << 24 | 0x00FFFFFF;
  }

  if (key == '.') {
    int currentOpacity = ((opacity >> 24) & 0xFF);
    currentOpacity = constrain(currentOpacity + 16, 1, 255);
    opacity = currentOpacity << 24 | 0x00FFFFFF;
  }

  if (key == 'x' || key == 'y' || key == 'z') {
    if (key == 'x') {
      rotXW = !rotXW;
    }

    if (key == 'y') {
      rotYW = !rotYW;
    }
    if (key == 'z') {
      rotZW = !rotZW;
    }
    defaultTheta = 0.01;
  }

  if (key == 'X' || key == 'Y' || key == 'Z') {
    if (key == 'X') {
      rotXW = !rotXW;
    }

    if (key == 'Y') {
      rotYW = !rotYW;
    }
    if (key == 'Z') {
      rotZW = !rotZW;
    }
    defaultTheta = -0.01;
  }

  if (key == 'r') {
    rotXW = rotYW = rotZW = false;
    fromColumnVector4D = new FloatMatrix(from);
    fromRowVector4D = fromColumnVector4D.dup().reshape(1, 4);
    toMatrix = new FloatMatrix(to).dup();
    upMatrix = new FloatMatrix(up).dup();
    overMatrix = new FloatMatrix(over).dup();

    transform4D = Calc4Matrix(fromColumnVector4D, toMatrix, upMatrix, overMatrix);
    cam1.jump(from[0], from[1], from[2]);
    cam1.aim(aimAt[0], aimAt[1], aimAt[2]);
    if (stereo) {
      cam2.jump(from[0], from[1], from[2]);
      cam2.aim(aimAt[0], aimAt[1], aimAt[2]);
      cam1.circle(interocularAngle);
      cam2.circle(-interocularAngle);
    }
    project4Dcells();
  }


  if (key == 'f') {
    facesActive = !facesActive;
  }
  if (key == 'l') {
    labelsActive = !labelsActive;
  }
  if (key == 'k') {
    lockTo4DViewpoint = !lockTo4DViewpoint;
  }
  if (key == 'i') {
    namesActive = !namesActive;
  }
  if (key == 'N') {
    normalsActive = !normalsActive;
  }
  if (key == 'h' || key == '/' || key == '?') {
    helpActive = !helpActive;
  }
  if (key == 'p') {
    if (proj_type == "PARALLEL") proj_type = "PERSPECTIVE";
    else proj_type = "PARALLEL";
    project4Dcells();
  }
  if (key == ' ') {
    stereo = !stereo;
    if (stereo) {
      float[] pos = cam1.position();
      cam2.jump(pos[0], pos[1], pos[2]);
      cam2.aim(aimAt[0], aimAt[1], aimAt[2]);
      cam1.circle(-interocularAngle);
      cam2.circle(interocularAngle);
    }
  }

  if (key == '1' || key == '2' || key == '3' || key == '4' || key == '5' || key == '6' || key == '7') {
    loadNewModel(int(str(key)));
  }

  if (key == CODED) {
    if (keyCode == 157 || keyCode == 18) {  // holding command/alt key
      panning = true;
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == 157 || keyCode == 18) {   // release command key
      panning = false;
    }
  }
}

void mouseDragged() {
  if (panning) {
    float mul = -0.001;
    float[] pos = cam1.position();
    float[] target = cam1.target();
    mul *= sqrt(pow(target[0]-pos[0], 2) + pow(target[1]-pos[1], 2) + pow(target[2]-pos[2], 2));
    cam1.track((mouseX - pmouseX)*mul, (mouseY - pmouseY)*mul);
    if (stereo) cam2.track((mouseX - pmouseX)*mul, (mouseY - pmouseY)*mul);
    //    if (axesActive) camAxes.track((mouseX - pmouseX)*mul, (mouseY - pmouseY)*mul);
  }
  else {
    cam1.tumble(-radians(mouseX - pmouseX), -radians(mouseY - pmouseY));
    if (stereo) cam2.tumble(-radians(mouseX - pmouseX), -radians(mouseY - pmouseY));
    //    if (axesActive) camAxes.tumble(-radians(mouseX - pmouseX), -radians(mouseY - pmouseY));
  }
}


void loadNewModel(int i) {
  switch (i) {
  case 1:
    cells = genAxes();
    modelName = "axes";
    break;
  case 2:
    cells = genFromVEFCfile("data/5cell_vefc.txt");
    modelName = "5-cell (hyperpyramid)";
    break;
  case 3:
    cells = genFromVEFCfile("data/8cell_vefc.txt");
    modelName = "8-cell (hypercube)";
    break;
  case 4:
    cells = genFromVEFCfile("data/16cell_vefc.txt");
    modelName = "16-cell (hyperoctahedron)";
    break;
  case 5:
    cells = genFromVEFCfile("data/24cell_vefc.txt");
    modelName = "24-cell";
    break;
  case 6:
    cells = genFromVEFCfile("data/120cell_vefc.txt");
    modelName = "120-cell";
    break;
  case 7:
    cells = genFromVEFCfile("data/600cell_vefc.txt");
    modelName = "600-cell";    
    break;
  }

  project4Dcells();
}

void addLabels(Cell cell) {
  FloatMatrix temp = (FloatMatrix) cell.vertices.get(0).dup();
  for (int j = 1; j < cell.vertices.size(); j++) {
    temp.addi((FloatMatrix) cell.vertices.get(j));
  }
  temp.divi(cell.vertices.size());
  String label = str(cell.cellNum);
  FloatMatrix temp2 = project4Dvector(temp);
  labels.add(new Label(label, myScreenX(temp2.get(0), temp2.get(1), temp2.get(2)), myScreenY(temp2.get(0), temp2.get(1), temp2.get(2)), cell.cellColor));
}

void addLabels(Face3 face) {
  FloatMatrix temp = (FloatMatrix) face.vertices.get(0).dup();
  for (int j = 1; j < face.vertices.size(); j++) {
    temp.addi((FloatMatrix) face.vertices.get(j));
  }
  temp.divi(face.vertices.size());

  ListIterator itr = face.vertices.listIterator();
  while (itr.hasNext ()) {
    FloatMatrix vert3 = (FloatMatrix) itr.next();
    FloatMatrix vert4 = (FloatMatrix) face.oldVertices.get(itr.previousIndex());
    String label = str(face.faceNum);

    if (faceLabels) labels.add(new Label(label, myScreenX(temp.get(0), temp.get(1), temp.get(2)), myScreenY(temp.get(0), temp.get(1), temp.get(2)), face.faceColor));
    label = str((int) face.numberedVertices.get(itr.previousIndex()));
    float x = myScreenX(vert3.get(0), vert3.get(1), vert3.get(2));
    float y = myScreenY(vert3.get(0), vert3.get(1), vert3.get(2));
    if (vertexLabels) labels.add(new Label(label, x, y));
    if (vertexCoordLabels) {
      label = "(";
      label += nf(vert4.get(0), 1, 2) + ", ";
      label += nf(vert4.get(1), 1, 2) + ", ";
      label += nf(vert4.get(2), 1, 2) + ", ";
      label += nf(vert4.get(3), 1, 2) + ")";
      labels.add(new Label(label, x, y));
    }
  }
}

void drawLabels() {
  camera();
  ortho(0, width, 0, height, -10, 10);

  if (fps) labels.add(new Label(nf(frameRate, 2, 2), width - 40, 10, color(255)));

  if (helpActive) {
    int i = 20;
    for (String h : helpText) {
      labels.add(new Label(h, 10, i, color(255)));
      i += 10;
    }
  }

  if (namesActive) {
    labels.add(new Label(modelName, width/2 - (modelName.length() * 4), 10, color(255)));
  }

  Iterator itr = labels.iterator();
  while (itr.hasNext ()) {
    Label l = (Label) itr.next();
    fill(l.labelColor);
    l.draw();
  }
}


void cellIsVisible(Cell cell) {
  FloatMatrix temp = (FloatMatrix) cell.vertices.get(0).dup();
  for (int j = 1; j < cell.vertices.size(); j++) {
    temp.addi((FloatMatrix) cell.vertices.get(j));
  }
  temp.divi(cell.vertices.size());
  float thisResult = fromColumnVector4D.dup().sub(temp).dot(cell.normal);
  if (thisResult < 0) {
    cell.visible = false;
  }
  else {
    cell.visible = true;
  }
}

void drawCellNormal(Cell cell) {
  FloatMatrix temp = (FloatMatrix) cell.vertices.get(0).dup();
  for (int j = 1; j < cell.vertices.size(); j++) {
    temp.addi((FloatMatrix) cell.vertices.get(j));
  }
  temp.divi(cell.vertices.size());


  ArrayList<FloatMatrix> normal3D = new ArrayList<FloatMatrix>();
  normal3D.add(project4Dvector(temp));
  normal3D.add(project4Dvector(cell.normal.dup().add(temp)));

  color thisColor = cell.cellColor;
  float thisResult = fromColumnVector4D.dup().sub(temp).dot(cell.normal);
  if (thisResult < 0) {
    thisColor = color(255, 0, 0);  // cell normal is pointing away from camera
  }
  stroke(thisColor);

  beginShape(LINES);
  vertex(normal3D.get(0).get(0), normal3D.get(0).get(1), normal3D.get(0).get(2));
  vertex(normal3D.get(1).get(0), normal3D.get(1).get(1), normal3D.get(1).get(2));
  endShape();
}


void mousePressed() {
  if (mouseEvent.getClickCount()==2) {
    cam1.jump(cameraFrom[0], cameraFrom[1], cameraFrom[2]);
    if (stereo) {
      cam1.circle(-interocularAngle);
      cam2.jump(cameraFrom[0], cameraFrom[1], cameraFrom[2]);
      cam2.circle(interocularAngle);
    }
    cameraRecenter();
  }
}
void mouseWheel(int delta) {
  cam1.dolly(delta/5.0);
  cam1.aim(aimAt[0], aimAt[1], aimAt[2]);
  if (stereo) {
    cam2.dolly(delta/5.0);
    cam2.aim(aimAt[0], aimAt[1], aimAt[2]);
  }
}

public float myScreenX(float x, float y, float z) {
  float ax = pgl.modelview.m00 * x + pgl.modelview.m01 * y + pgl.modelview.m02 * z + pgl.modelview.m03;
  float ay = pgl.modelview.m10 * x + pgl.modelview.m11 * y + pgl.modelview.m12 * z + pgl.modelview.m13;
  float az = pgl.modelview.m20 * x + pgl.modelview.m21 * y + pgl.modelview.m22 * z + pgl.modelview.m23;
  float aw = pgl.modelview.m30 * x + pgl.modelview.m31 * y + pgl.modelview.m32 * z + pgl.modelview.m33;

  float ox = pgl.projection.m00 * ax + pgl.projection.m01 * ay + pgl.projection.m02 * az + pgl.projection.m03 * aw;
  float ow = pgl.projection.m30 * ax + pgl.projection.m31 * ay + pgl.projection.m32 * az + pgl.projection.m33 * aw;

  if (ow != 0) {
    ox /= ow;
  }
  float sx = width * (1 + ox) / 2.0f;
  return sx;
}


public float myScreenY(float x, float y, float z) {        
  float ax = pgl.modelview.m00 * x + pgl.modelview.m01 * y + pgl.modelview.m02 * z + pgl.modelview.m03;
  float ay = pgl.modelview.m10 * x + pgl.modelview.m11 * y + pgl.modelview.m12 * z + pgl.modelview.m13;
  float az = pgl.modelview.m20 * x + pgl.modelview.m21 * y + pgl.modelview.m22 * z + pgl.modelview.m23;
  float aw = pgl.modelview.m30 * x + pgl.modelview.m31 * y + pgl.modelview.m32 * z + pgl.modelview.m33;

  float oy = pgl.projection.m10 * ax + pgl.projection.m11 * ay + pgl.projection.m12 * az + pgl.projection.m13 * aw;
  float ow = pgl.projection.m30 * ax + pgl.projection.m31 * ay + pgl.projection.m32 * az + pgl.projection.m33 * aw;

  if (ow != 0) {
    oy /= ow;
  }    
  float sy = height * (1 + oy) / 2.0f;
  // Inverting result because of Processing' inverted Y axis.
  sy = height - sy;
  return sy;
}

