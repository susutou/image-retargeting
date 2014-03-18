from cImage import *
import random

def checkInside(sizex, sizey, posx, posy):
  return (posx>0 and posx<sizex and posy>0 and posy<sizey)

def clickedOnRetarget(pos,button):
  return checkInside(button.getWidth(), button.getHeight(), pos[0]-0, pos[1]-0)

def clickedOnQuit(pos, button):
  return checkInside(button.getWidth(), button.getHeight(), pos[0]-600, pos[1]-0)

def fillWhiteImage(im):
  for i in range(im.getWidth()):
    for j in range(im.getHeight()):
      im.setPixel(i,j, Pixel(255,255,255))

def convertImage2Matrix(im):
  h = im.getHeight()
  w = im.getWidth()
  mat = []
  for i in range(h):
    mat.append([])
    for j in range(w):
      mat[i].append([255,255,255])
  
  for row in range(h):
    for col in range(w):
      mat[row][col][0] = (im.getPixel(col, row)).getRed()
      mat[row][col][1] = (im.getPixel(col, row)).getGreen()
      mat[row][col][2] = (im.getPixel(col, row)).getBlue()
  return mat

def convertMatrix2Image(mat):
  h = len(mat)
  w = len(mat[0])
  im = EmptyImage(w, h)
  for row in range(h):
    for col in range(w):
##      pix = im.getPixel(col, row)
##      pix.setRed(mat[row][col][0])
##      pix.setGreen(mat[row][col][1])
##      pix.setBlue(mat[row][col][2])
      pix = Pixel(mat[row][col][0], mat[row][col][1], mat[row][col][2])
      im.setPixel(col, row, pix)
  return im
  
def randomDelete(inmat):
  h = len(inmat)
  w = len(inmat[0])
  outmat = []
  for row in range(h):
    outmat.append([])
    col_bad = random.randint(0, w-1)
    for col in range(w):
      if (col_bad != col):
        outmat[row].append(list(inmat[row][col]))
  print(len(outmat), len(outmat[0]))
  return outmat
      

def pixIntensity(p):
  return sum(p)//3


dp = []
direction = []
to_delete = []


def seamCarving(inmat, energyFunc = pixIntensity):
  h = len(inmat)
  w = len(inmat[0])
  for row in range(1, h):
    for col in range(w):
      dp[row][col] = 10000 # inf
      for d in [-1, 0, 1]:
        if (col + d>=0) and (col + d < w):
          # new_value = dp[row-1][col+d] + abs(energyFunc(inmat[row][col]) - energyFunc(inmat[row-1][col + d]))
          new_value = dp[row-1][col+d] + abs(sum(inmat[row][col])//3 -sum(inmat[row-1][col + d])//3)
          if new_value < dp[row][col]:
            dp[row][col] = new_value
            direction[row][col] = d
  # collect the to-delete column numbers

  # print(dp[-1])
  print(h,w)
  to_delete[h - 1] = dp[h-1].index(min(dp[h-1])) # the index of max number
  for i in range(h-2, -1, -1):
    # print(direction[i+1][to_delete[i+1]], ",")
    to_delete[i] = to_delete[i+1] + direction[i+1][to_delete[i+1]]
  # print(to_delete[-1])
  # print(to_delete)
  for i in range(h):
    # print(to_delete[i])
    inmat[i].pop(to_delete[i])
    dp[i].pop()
    direction[i].pop()
  
    
def retarget(mat, func, threads):
  for i in range(threads):
    func(mat)



myWin = ImageWin("Framework", 1000,1000)
red_button = FileImage("red_button.gif")
red_button.setPosition(0,0) # button for retarget
red_button.draw(myWin)
red_button.setPosition(600, 0) # button for quit 
red_button.draw(myWin)

one = FileImage("light-tower.gif")
one.setPosition(0, red_button.getHeight())
one.draw(myWin)
one.setPosition(0, red_button.getHeight() + one.getHeight())
one.draw(myWin)
one_mat = convertImage2Matrix(one)
one_white = EmptyImage(one.getWidth(), one.getHeight())
one_white.setPosition(0, red_button.getHeight())
fillWhiteImage(one_white)

print("height =", red_button.getHeight(), "   width=",red_button.getWidth())

h = len(one_mat)
w = len(one_mat[0])
# dynamic programming
dp = []
direction = []
for i in range(h):
  dp.append([])
  direction.append([])
  for j in range(w):
    dp[i].append(0)
    direction[i].append(0)
to_delete = [0] * h

while True:
  pos = myWin.getMouse()
  print(pos)  # (x,y)
  if clickedOnRetarget(pos, red_button):
    for i in range(5):
      # one = retarget(one, randomDelete, 100)
      retarget(one_mat, seamCarving, 20)
      one = convertMatrix2Image(one_mat)
      print("one: ", one.getWidth(), one.getHeight())
      one.setPosition(0, red_button.getHeight())
      one_white.draw(myWin)
      one.draw(myWin)
    print("clicked on retargeting button")
    
  elif clickedOnQuit(pos, red_button):
    print("click anywhere to quit")
    break

myWin.exitOnClick()
