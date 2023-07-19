#include <SFML/Graphics.hpp>
#include <SFML/OpenGL.hpp>
#include <SFML/Window.hpp>
#include <iostream>
#include <cmath>
#include <ctime>

#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>

// Including resource files path

#include "ResourcePath.hpp"


using namespace std;
using namespace sf;


// Framerate class

class FPS{
public:
    FPS(): mFrame(0), mFps(0) {}
    unsigned int getFPS() const { return mFps; }
    
    void update(){
        if(mClock.getElapsedTime().asSeconds() >= 1.f){ mFps = mFrame; mFrame = 0; mClock.restart(); }
        mFrame++;
    }
    
private:
    unsigned int mFrame, mFps;
    Clock mClock;
};


// Global varibales

float WIDTH = 720, HEIGHT = 720, H_WIDTH = WIDTH / 2, H_HEIGHT = HEIGHT / 2, ASPECT_RATIO = WIDTH / HEIGHT;


Vector3f normalize(Vector3f v){
    float length = sqrt(v.x*v.x + v.y * v.y + v.z*v.z);
    return {v.x / length, v.y / length, v.z / length};
}

// Main function

int main() {
    FPS fps;
    
    RenderWindow window(VideoMode(WIDTH, HEIGHT), "Ray Marching v4.0");
    window.setFramerateLimit(60);
    window.setVerticalSyncEnabled(true);
    
    if (!Shader::isAvailable()){
        printf("Shaders is not supported");
        return -1;
    }
    
    Shader fragShader;
    
    if (!fragShader.loadFromFile(resourcePath() + "Shader.glsl", Shader::Fragment)){
        printf("can't find this shader");
        return -1;
    }

    ContextSettings settings = window.getSettings();
    std::cout << settings.depthBits << " " << settings.stencilBits << " " << settings.antialiasingLevel;
    // Camera Varibales
    
    Vector3f CameraPos = {0, 2.5, -5}, MeshPos = {0., 0., 0.};
//    Vector3f CameraPos = {4.307, -0.093, 11.87}, MeshPos = {0., 0., 0.};
    Vector2i omPos = Mouse::getPosition();
    float mouseX = H_WIDTH, mouseY = H_HEIGHT;
//    float mouseX = -3787, mouseY = 410;
    float MeshScale = 0.726f, ma = 0.f, Pfov = 10., alpha = 1./64;
    bool cursorLocked = true, record = 0, freeMov = 1, useAllining = true;
    int frNum = 0, tick = 0, frStill = 1, frForRenderNum = 512, raysPerPixel = 16;
    
    // Main cycle
    
    while (window.isOpen()){
        // User-input and Window events updating
        
        Event event;
        while (window.pollEvent(event)){
            if (event.type == Event::Closed)
                window.close();
            
            if (event.type == Event::KeyPressed){
                if (Keyboard::isKeyPressed(Keyboard::F)) raysPerPixel *= 2;
                if (Keyboard::isKeyPressed(Keyboard::G)) { raysPerPixel = 1; alpha = 1.f; MeshPos = {0.365, -0.52, 0.36}; MeshScale = 0.726; }
                if (Keyboard::isKeyPressed(Keyboard::Escape)) cursorLocked ^= 1, !cursorLocked ? omPos = Mouse::getPosition(), 1 : 0;
                if (Keyboard::isKeyPressed(Keyboard::T)) window.clear(), useAllining ^= 1, frStill *= useAllining;
                if (Keyboard::isKeyPressed(Keyboard::V)) freeMov ^= 1;
                if (Keyboard::isKeyPressed(Keyboard::P)) printf("Camera position: %f %f %f, camera rotation: %f %f \n", CameraPos.x, CameraPos.y, CameraPos.z, mouseX, mouseY);
                if (Keyboard::isKeyPressed(Keyboard::R)) record ^= 1, window.clear(), window.display(), tick = 1, frForRenderNum = max(256 * record, 1), alpha = 4.f / frForRenderNum, printf(record ? "Recording started\n" : "Recording stopped\n");
                frStill = 1;
            }
                
            if (event.type == Event::MouseButtonPressed){
                string filename = resourcePath() + "../../../frames/screenshot.png";
                Texture texture;
                texture.create(window.getSize().x, window.getSize().y);
                texture.update(window);
                if (texture.copyToImage().saveToFile(filename)) printf("screenshot saved to %s\n", filename.c_str());
            }
        }
        
        // Mouse Events
        
        if (!cursorLocked && ((tick) % frForRenderNum == 1 || freeMov)){
            Vector2i mPos = Mouse::getPosition();
            float shift_x = omPos.x - mPos.x, shift_y = omPos.y - mPos.y;
//            omPos = mPos;
            mouseX += shift_x;
            mouseY += shift_y;
            if (shift_x != 0 || shift_y != 0) frStill = 1;
            Mouse::setPosition(omPos);
        }

        float mx = ((float)mouseX / WIDTH - 0.5f), my = ((float)mouseY / HEIGHT - 0.5f);

        // Camera movement
        
        Vector3f dir = Vector3f(0.0f, 0.0f, 0.0f), dirTemp;
        
        if ((tick) % frForRenderNum == 1 || freeMov){
            ma += 0.005 - 1.256 * (ma > 1.256);
            
            if (Keyboard::isKeyPressed(Keyboard::W)) dir = Vector3f(0.0f, 0.0f, 1.0f), frStill = 1;
            else if (Keyboard::isKeyPressed(Keyboard::S)) dir = Vector3f(0.0f, 0.0f, -1.0f), frStill = 1;
            if (Keyboard::isKeyPressed(Keyboard::A)) dir += Vector3f(-1.0f, 0.0f, 0.0f), frStill = 1;
            else if (Keyboard::isKeyPressed(Keyboard::D)) dir += Vector3f(1.0f, 0.0f, 0.0f), frStill = 1;
        
//            if (Keyboard::isKeyPressed(Keyboard::I)) MeshPos.z += 0.005f;
//            else if (Keyboard::isKeyPressed(Keyboard::K)) MeshPos.z -= 0.005f;
//            if (Keyboard::isKeyPressed(Keyboard::L)) MeshPos.x += 0.005f;
//            else if (Keyboard::isKeyPressed(Keyboard::J)) MeshPos.x -= 0.005f;
//            if (Keyboard::isKeyPressed(Keyboard::O)) MeshPos.y += 0.005f;
//            else if (Keyboard::isKeyPressed(Keyboard::U)) MeshPos.y -= 0.005f;
//
//            if (Keyboard::isKeyPressed(Keyboard::Y)) MeshScale *= 1.05f;
//            else if (Keyboard::isKeyPressed(Keyboard::H)) MeshScale *= 0.95f;

            if (Keyboard::isKeyPressed(Keyboard::Q)) CameraPos.y -= 0.25f, frStill = 1;
            else if (Keyboard::isKeyPressed(Keyboard::E)) CameraPos.y += 0.25f, frStill = 1;
            
            
//            if (Keyboard::isKeyPressed(Keyboard::X)) Pfov -= 0.25f;
//            else if (Keyboard::isKeyPressed(Keyboard::Z)) Pfov += 0.25f;

        }
            
        dirTemp.y = dir.y * cos(my * 0.5f) - dir.z * sin(my * 0.5f);
        dirTemp.z = dir.y * sin(my * 0.5f) + dir.z * cos(my * 0.5f);
        dirTemp.x = dir.x;
        dir.y = dirTemp.y;
        dir.x = dirTemp.x * cos(mx) - dirTemp.z * sin(mx);
        dir.z = dirTemp.x * sin(mx) + dirTemp.z * cos(mx);
        
        CameraPos += dir * 0.25f;

        Vector2f resolution = (Vector2f)window.getSize();
        RectangleShape rect(resolution);
        
        // Shader applying
        
        fragShader.setUniform("resolution", resolution);
        fragShader.setUniform("rayOrigin", CameraPos);
//        fragShader.setUniform("mo", MeshPos);
//        fragShader.setUniform("ms", MeshScale);
        fragShader.setUniform("u_mouse", Vector2f(mx, my));
        fragShader.setUniform("time", (clock()/(float)CLOCKS_PER_SEC) - int(clock()/(float)CLOCKS_PER_SEC));
        
        fragShader.setUniform("rand0", ((float) rand() / (RAND_MAX)) - 0.5f);
        fragShader.setUniform("rand1", ((float) rand() / (RAND_MAX)) - 0.5f);
        fragShader.setUniform("rand2", ((float) rand() / (RAND_MAX)) - 0.5f);
        
        fragShader.setUniform("alpha", 1.f / frStill);
        fragShader.setUniform("tick", tick);
        fragShader.setUniform("samples", raysPerPixel);
//        fragShader.setUniform("heavy", heavy);

        RenderStates shader(&fragShader);
        window.draw(rect, shader);

        // Screen updating

        fps.update();
        window.setTitle("Ray Marching v4.0 fps: " + to_string(fps.getFPS()) + (record ? " recording frame: " + to_string(frNum) : ""));
        window.display();
        
        if (record && tick == 0){
//            window.display();
            string str_num = to_string(frNum);
            int z_num = 4 - str_num.size();
            string filename = resourcePath() + "../../../frames/" + string(z_num, '0') + str_num + ".png";
            Texture texture;
            texture.create(window.getSize().x, window.getSize().y);
            texture.update(window);
            texture.copyToImage().saveToFile(filename);
            frNum++;
            frStill = 0;
            window.display();
            window.clear();
        }
        
        tick++;
        tick %= frForRenderNum;
        frStill += useAllining;
//        frStill = min(256, frStill);
    }

    return 0;
}
