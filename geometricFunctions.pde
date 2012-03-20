FloatMatrix Calc4Matrix(FloatMatrix from, FloatMatrix to, FloatMatrix up, FloatMatrix over) {
  float norm;
  FloatMatrix cameraTransform;
  Wd = to.sub(from);

  norm = Wd.norm2();
  if (norm == 0) {
    println("To point and From point are the same.");
  }
  Wd.muli(1/norm);

  Wa = cross4(up, over, Wd);
  norm = Wa.norm2();
  if (norm == 0) {
    println("Invalid Up vector.");
  }
  Wa.muli(1/norm);

  Wb = cross4(over, Wd, Wa);
  norm = Wb.norm2();
  if (norm == 0) {
    println("Invalid Over vector.");
  }
  Wb.muli(1/norm);

  Wc = cross4(Wd, Wa, Wb);
  FloatMatrix step1 = Wa.concatHorizontally(Wa, Wb);
  FloatMatrix step2 = Wa.concatHorizontally(step1, Wc);


  return step2.concatHorizontally(step2, Wd);
}

FloatMatrix cross3(FloatMatrix a, FloatMatrix b) {
  FloatMatrix product = new FloatMatrix(3);
  product.put(0, a.get(1)*b.get(2) - a.get(2)*b.get(1));
  product.put(1, a.get(2)*b.get(0) - a.get(0)*b.get(2));
  product.put(2, a.get(0)*b.get(1) - a.get(1)*b.get(0));
  return product;
}

FloatMatrix cross4(FloatMatrix U, FloatMatrix V, FloatMatrix W) {
  float A, B, C, D, E, F;
  FloatMatrix result = new FloatMatrix(4);
  A = (V.get(0) * W.get(1)) - (V.get(1) * W.get(0));
  B = (V.get(0) * W.get(2)) - (V.get(2) * W.get(0));
  C = (V.get(0) * W.get(3)) - (V.get(3) * W.get(0));
  D = (V.get(1) * W.get(2)) - (V.get(2) * W.get(1));
  E = (V.get(1) * W.get(3)) - (V.get(3) * W.get(1));
  F = (V.get(2) * W.get(3)) - (V.get(3) * W.get(2));

  // Calculate the result-vector components.

  result.put(0, (U.get(1) * F) - (U.get(2) * E) + (U.get(3) * D));
  result.put(1, (U.get(0) * F) + (U.get(2) * C) - (U.get(3) * B));
  result.put(2, (U.get(0) * E) - (U.get(1) * C) + (U.get(3) * A));
  result.put(3, -(U.get(0) * D) + (U.get(1) * B) - (U.get(2) * A));

  return result;
}

void rotateXW(float theta) {
  if (theta != lastXWtheta) {
    xwMatrix = FloatMatrix.eye(4);
    xwMatrix.put(0, 0, cos(theta));
    xwMatrix.put(3, 3, cos(theta));
    xwMatrix.put(0, 3, sin(theta));
    xwMatrix.put(3, 0, -1*sin(theta));
    lastXWtheta = theta;
  }
  fromRowVector4D.mmuli(xwMatrix);
  fromColumnVector4D = fromRowVector4D.dup().reshape(4, 1);
  upMatrix.reshape(1, 4).mmuli(xwMatrix).reshape(4, 1);
  overMatrix.reshape(1, 4).mmuli(xwMatrix).reshape(4, 1);
}
void rotateYW(float theta) {
  if (theta != lastYWtheta) {
    ywMatrix = FloatMatrix.eye(4);
    ywMatrix.put(1, 1, cos(theta));
    ywMatrix.put(3, 3, cos(theta));
    ywMatrix.put(1, 3, sin(theta));
    ywMatrix.put(3, 1, -1*sin(theta));
    lastYWtheta = theta;
  }
  fromRowVector4D.mmuli(ywMatrix);
  fromColumnVector4D = fromRowVector4D.dup().reshape(4, 1);
  upMatrix.reshape(1, 4).mmuli(ywMatrix).reshape(4, 1);
  overMatrix.reshape(1, 4).mmuli(ywMatrix).reshape(4, 1);
}
void rotateZW(float theta) {
  if (theta != lastZWtheta) {
    zwMatrix = FloatMatrix.eye(4);
    zwMatrix.put(2, 2, cos(theta));
    zwMatrix.put(3, 3, cos(theta));
    zwMatrix.put(2, 3, sin(theta));
    zwMatrix.put(3, 2, -1*sin(theta));
    lastZWtheta = theta;
  }
  fromRowVector4D.mmuli(zwMatrix);
  fromColumnVector4D = fromRowVector4D.dup().reshape(4, 1);
  upMatrix.reshape(1, 4).mmuli(zwMatrix).reshape(4, 1);
  overMatrix.reshape(1, 4).mmuli(zwMatrix).reshape(4, 1);
}

FloatMatrix[] gramSchmidt(FloatMatrix[] vecs) {
  FloatMatrix u[] = new FloatMatrix[vecs.length];
  for (int i = 0; i < vecs.length; i++) {
    u[i] = vecs[i].dup();
    for (int j = 0; j < i; j++) {
      u[i].subi(u[j].mul(vecs[i].dot(u[j])/u[j].dot(u[j])));
    }
    u[i].divi(u[i].norm2());
  }
  return u;
}

FloatMatrix cellNormal(Cell cell) {
  FloatMatrix temp = (FloatMatrix) cell.vertices.get(0).dup();
  for (int j = 1; j < cell.vertices.size(); j++) {
    temp.addi((FloatMatrix) cell.vertices.get(j));
  }
  temp.divi(cell.vertices.size());

  ArrayList<FloatMatrix> normal = new ArrayList<FloatMatrix>();
  
  FloatMatrix v[] = new FloatMatrix[3];
  for (int i = 0; i < 3; i++) {
    v[i] = cell.vertices.get(i).dup().sub(temp);
  }
  FloatMatrix vecs[] = gramSchmidt(v);

  FloatMatrix d = cross4(vecs[0], vecs[1], vecs[2]);
  float norm = d.norm2();
  d.muli(1/norm);
  
  return d;
}

