package de.matze.zombiecity;

import android.content.Context;
import android.graphics.*;
import android.view.*;
import java.util.*;

public final class GameView extends View implements Runnable {
    private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random rng = new Random();
    private final ArrayList<Zombie> zombies = new ArrayList<>();
    private final int[][] map = {
        {1,1,1,1,1,1,1,1,1,1,1,1}, {1,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,1,0,0,0,1,0,0,0,1}, {1,0,0,1,0,0,0,1,0,0,0,1},
        {1,0,0,0,0,1,0,0,0,1,0,1}, {1,0,0,0,0,1,0,0,0,1,0,1},
        {1,0,1,0,0,0,0,1,0,0,0,1}, {1,0,1,0,0,0,0,1,0,0,0,1},
        {1,0,0,0,1,0,0,0,0,1,0,1}, {1,0,0,0,1,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,1}, {1,1,1,1,1,1,1,1,1,1,1,1}
    };
    private Thread loop; private boolean running;
    private float px=2.5f, py=2.5f, angle=0, moveX, moveY, lookLastX;
    private int hp=100, ammo=12, reserve=72, wave=1, score=0, flash=0;
    private long lastFrame, nextShot, hurtAt; private boolean gameOver;
    private int movePointer=-1, lookPointer=-1; private float joyX,joyY;

    public GameView(Context c){ super(c); p.setTypeface(Typeface.create("sans",Typeface.BOLD)); setFocusable(true); spawnWave(); }
    @Override protected void onAttachedToWindow(){ super.onAttachedToWindow(); running=true; loop=new Thread(this,"ZombieLoop"); loop.start(); }
    @Override protected void onDetachedFromWindow(){ running=false; super.onDetachedFromWindow(); }
    @Override public void run(){ lastFrame=System.nanoTime(); while(running){ long n=System.nanoTime(); float dt=Math.min(.04f,(n-lastFrame)/1e9f); lastFrame=n; update(dt); postInvalidate(); try{Thread.sleep(16);}catch(Exception ignored){} } }

    private void update(float dt){
        if(gameOver)return;
        float f=-moveY/70f, s=moveX/70f, speed=2.25f*dt;
        tryMove((float)(Math.cos(angle)*f-Math.sin(angle)*s)*speed,(float)(Math.sin(angle)*f+Math.cos(angle)*s)*speed);
        for(Zombie z:zombies){ if(!z.alive)continue; float dx=px-z.x,dy=py-z.y,d=(float)Math.hypot(dx,dy); if(d>.48f){float step=Math.min(.55f*dt,d-.45f); float nx=z.x+dx/d*step,ny=z.y+dy/d*step;if(open(nx,ny)){z.x=nx;z.y=ny;}} else if(System.currentTimeMillis()>hurtAt){hp-=10;hurtAt=System.currentTimeMillis()+650;flash=5;if(hp<=0){hp=0;gameOver=true;}} }
        if(flash>0)flash--; boolean any=false; for(Zombie z:zombies)if(z.alive)any=true; if(!any){wave++;ammo=Math.min(12,ammo+4);reserve+=12;spawnWave();}
    }
    private boolean open(float x,float y){return x>.15f&&y>.15f&&x<11.85f&&y<11.85f&&map[(int)y][(int)x]==0;}
    private void tryMove(float dx,float dy){if(open(px+dx,py))px+=dx;if(open(px,py+dy))py+=dy;}
    private void spawnWave(){zombies.clear();int count=3+wave*2;for(int i=0;i<count;i++){float x,y;do{x=1.5f+rng.nextInt(9);y=1.5f+rng.nextInt(9);}while(!open(x,y)||Math.hypot(x-px,y-py)<3);zombies.add(new Zombie(x,y));}}

    @Override protected void onDraw(Canvas c){super.onDraw(c);int w=getWidth(),h=getHeight(); if(w==0)return;
        p.setShader(new LinearGradient(0,0,0,h/2f,Color.rgb(18,22,26),Color.rgb(80,72,62),Shader.TileMode.CLAMP));c.drawRect(0,0,w,h/2f,p);
        p.setShader(new LinearGradient(0,h/2f,0,h,Color.rgb(55,50,45),Color.rgb(12,12,12),Shader.TileMode.CLAMP));c.drawRect(0,h/2f,w,h,p);p.setShader(null);
        int rays=Math.min(w,480);float[] depth=new float[rays];
        for(int i=0;i<rays;i++){float ra=angle-.58f+1.16f*i/(rays-1f),d=0;while(d<18){d+=.035f;float x=px+(float)Math.cos(ra)*d,y=py+(float)Math.sin(ra)*d;if(!open(x,y))break;}d*=Math.cos(ra-angle);depth[i]=d;float wall=Math.min(h,h/(d+.02f));int shade=(int)Math.max(28,165-d*10);p.setColor(Color.rgb(shade,shade*9/10,shade*4/5));float x=i*w/(float)rays;c.drawRect(x,h/2f-wall/2,x+w/(float)rays+1,h/2f+wall/2,p);}
        ArrayList<Zombie> sorted=new ArrayList<>(zombies);sorted.sort((a,b)->Float.compare(dist(b),dist(a)));
        for(Zombie z:sorted)drawZombie(c,z,w,h,depth);
        drawWeapon(c,w,h);drawHud(c,w,h);drawControls(c,w,h);if(flash>0){p.setColor(0x55ff0000);c.drawRect(0,0,w,h,p);}if(gameOver)drawGameOver(c,w,h);
    }
    private float dist(Zombie z){return(float)Math.hypot(z.x-px,z.y-py);}
    private void drawZombie(Canvas c,Zombie z,int w,int h,float[] depth){if(!z.alive)return;float dx=z.x-px,dy=z.y-py,d=(float)Math.hypot(dx,dy),rel=wrap((float)Math.atan2(dy,dx)-angle);if(Math.abs(rel)>.68f)return;int sx=(int)(w/2+rel/.58f*w/2);int size=(int)Math.min(h*.9f,h/(d+.05f));int ri=Math.max(0,Math.min(depth.length-1,sx*depth.length/w));if(d>depth[ri]+.3f)return;int top=h/2-size/2;p.setColor(0xff26382b);c.drawOval(sx-size*.18f,top,sx+size*.18f,top+size*.34f,p);p.setColor(0xff394a32);c.drawRect(sx-size*.25f,top+size*.28f,sx+size*.25f,top+size*.78f,p);p.setColor(0xff111111);c.drawRect(sx-size*.2f,top+size*.75f,sx-size*.03f,top+size,p);c.drawRect(sx+size*.03f,top+size*.75f,sx+size*.2f,top+size,p);p.setColor(Color.RED);c.drawCircle(sx-size*.07f,top+size*.14f,Math.max(2,size*.02f),p);c.drawCircle(sx+size*.07f,top+size*.14f,Math.max(2,size*.02f),p);}
    private float wrap(float a){while(a>Math.PI)a-=Math.PI*2;while(a<-Math.PI)a+=Math.PI*2;return a;}
    private void drawWeapon(Canvas c,int w,int h){p.setColor(0xff202020);Path gun=new Path();gun.moveTo(w*.42f,h);gun.lineTo(w*.46f,h*.72f);gun.lineTo(w*.54f,h*.72f);gun.lineTo(w*.6f,h);gun.close();c.drawPath(gun,p);p.setColor(0xff777777);c.drawRect(w*.485f,h*.58f,w*.515f,h*.79f,p);if(flash>0){p.setColor(0xffffb300);c.drawCircle(w/2f,h*.56f,35,p);}p.setColor(Color.WHITE);p.setStrokeWidth(3);c.drawLine(w/2f-12,h/2f,w/2f-3,h/2f,p);c.drawLine(w/2f+3,h/2f,w/2f+12,h/2f,p);c.drawLine(w/2f,h/2f-12,w/2f,h/2f-3,p);c.drawLine(w/2f,h/2f+3,w/2f,h/2f+12,p);}
    private void drawHud(Canvas c,int w,int h){p.setTextSize(30);p.setColor(Color.WHITE);c.drawText("WELLE "+wave+"   PUNKTE "+score,24,42,p);p.setColor(hp<30?Color.RED:Color.WHITE);c.drawText("LEBEN "+hp,24,80,p);p.setColor(Color.WHITE);c.drawText(ammo+" / "+reserve,w-180,45,p);}
    private void drawControls(Canvas c,int w,int h){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(4);p.setColor(0x88ffffff);c.drawCircle(125,h-125,82,p);c.drawCircle(125+moveX,h-125+moveY,34,p);p.setStyle(Paint.Style.FILL);p.setColor(0x99b71c1c);c.drawCircle(w-105,h-110,65,p);p.setColor(Color.WHITE);p.setTextSize(22);c.drawText("FEUER",w-141,h-102,p);p.setColor(0x99c79200);c.drawCircle(w-225,h-65,42,p);p.setTextSize(15);p.setColor(Color.WHITE);c.drawText("LADEN",w-251,h-59,p);}
    private void drawGameOver(Canvas c,int w,int h){p.setColor(0xbb000000);c.drawRect(0,0,w,h,p);p.setTextAlign(Paint.Align.CENTER);p.setTextSize(60);p.setColor(Color.RED);c.drawText("DU BIST TOT",w/2f,h*.42f,p);p.setTextSize(28);p.setColor(Color.WHITE);c.drawText("Punkte: "+score+"  •  Tippen zum Neustart",w/2f,h*.55f,p);p.setTextAlign(Paint.Align.LEFT);}

    private void shoot(){long now=System.currentTimeMillis();if(gameOver||now<nextShot)return;if(ammo<=0){reload();return;}ammo--;nextShot=now+220;flash=3;Zombie best=null;float bestD=99;for(Zombie z:zombies){if(!z.alive)continue;float rel=Math.abs(wrap((float)Math.atan2(z.y-py,z.x-px)-angle)),d=dist(z);if(rel<.11f&&d<bestD&&lineClear(z.x,z.y)){best=z;bestD=d;}}if(best!=null){best.hp-=50;if(best.hp<=0){best.alive=false;score+=100;}}}
    private boolean lineClear(float tx,float ty){float d=(float)Math.hypot(tx-px,ty-py);for(float s=.1f;s<d;s+=.08f)if(!open(px+(tx-px)*s/d,py+(ty-py)*s/d))return false;return true;}
    private void reload(){int need=12-ammo,take=Math.min(need,reserve);ammo+=take;reserve-=take;}
    private void restart(){px=2.5f;py=2.5f;angle=0;hp=100;ammo=12;reserve=72;wave=1;score=0;gameOver=false;spawnWave();}
    @Override public boolean onTouchEvent(android.view.MotionEvent e){int action=e.getActionMasked(),idx=e.getActionIndex(),id=e.getPointerId(idx),w=getWidth(),h=getHeight();if(gameOver&&action==MotionEvent.ACTION_DOWN){restart();return true;}if(action==MotionEvent.ACTION_DOWN||action==MotionEvent.ACTION_POINTER_DOWN){float x=e.getX(idx),y=e.getY(idx);if(x>w-180&&y>h-210){shoot();return true;}if(x>w-290&&x<w-160&&y>h-135){reload();return true;}if(x<w*.42f&&movePointer<0){movePointer=id;joyX=x;joyY=y;}else if(lookPointer<0){lookPointer=id;lookLastX=x;}}else if(action==MotionEvent.ACTION_MOVE){for(int i=0;i<e.getPointerCount();i++){int pid=e.getPointerId(i);if(pid==movePointer){moveX=Math.max(-70,Math.min(70,e.getX(i)-joyX));moveY=Math.max(-70,Math.min(70,e.getY(i)-joyY));}else if(pid==lookPointer){float x=e.getX(i);angle+=(x-lookLastX)*.0052f;lookLastX=x;}}}else if(action==MotionEvent.ACTION_UP||action==MotionEvent.ACTION_POINTER_UP||action==MotionEvent.ACTION_CANCEL){if(id==movePointer){movePointer=-1;moveX=moveY=0;}if(id==lookPointer)lookPointer=-1;}return true;}
    private static final class Zombie{float x,y;int hp=100;boolean alive=true;Zombie(float x,float y){this.x=x;this.y=y;}}
}
