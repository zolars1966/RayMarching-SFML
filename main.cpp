#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>
#include <iostream>
#include <cmath>
#include <ctime>

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
    if (!Shader::isAvailable()){
        printf("Shaders is not supported");
        return -1;
    }
    
    Shader fragShader;
    
    if (!fragShader.loadFromFile(resourcePath() + "Shader.glsl", Shader::Fragment)){
        printf("can't find this shader");
        return -1;
    }
    
    FPS fps;
    RenderWindow window(VideoMode(WIDTH, HEIGHT), "Ray Marching v4.0");
    window.setFramerateLimit(60);
    window.setVerticalSyncEnabled(true);

    // Camera Varibales
    
    Vector3f CameraPos = {0, 12, -36}, MeshPos = {0., 0., 0.};
    Vector2i om_pos = Mouse::getPosition();
    float MeshScale = 0.726f, ma = 0.f, Pfov = 10., mouseX = H_WIDTH, mouseY = H_HEIGHT, alpha = 1./64;
    bool cursorLocked = true, trace = 0, record = 0, free_mov = 1, pers = 1, heavy = 0;
    int fr_num = 0, tick = 0, mode = 1, rpp = 256;
    
    // Main cycle
    
    while (window.isOpen()){
        // User-input and Window events updating
        
        Event event;
        while (window.pollEvent(event)){
            if (event.type == Event::Closed)
                window.close();
            
            if (event.type == Event::KeyPressed){
                if (Keyboard::isKeyPressed(Keyboard::F)) alpha /= 2.f;
                if (Keyboard::isKeyPressed(Keyboard::G)) { alpha = 1.f; MeshPos = {0.365, -0.52, 0.36}; MeshScale = 0.726; }
                if (Keyboard::isKeyPressed(Keyboard::Escape)) cursorLocked ^= 1, !cursorLocked ? om_pos = Mouse::getPosition(), 1 : 0;
                if (Keyboard::isKeyPressed(Keyboard::T)) trace ^= 1;
                if (Keyboard::isKeyPressed(Keyboard::V)) free_mov ^= 1;
                // if (Keyboard::isKeyPressed(Keyboard::P)) printf("%f %f %f", MeshPos.x, MeshPos.y, MeshPos.z);
                if (Keyboard::isKeyPressed(Keyboard::R)) record ^= 1, window.clear(), window.setFramerateLimit(60 * !record), window.setVerticalSyncEnabled(!record), trace = record, tick = 0, alpha = fmax(1/64., !record), printf(record ? "Recording started\n" : "Recording stopped\n");
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
        
        if (!cursorLocked && ((tick) % rpp == 1 || free_mov)){
            Vector2i m_pos = Mouse::getPosition();
            float shift_x = om_pos.x - m_pos.x, shift_y = om_pos.y - m_pos.y;
//            om_pos = m_pos;
            mouseX += shift_x;
            mouseY += shift_y;
            Mouse::setPosition(om_pos);
        }

        float mx = ((float)mouseX / WIDTH - 0.5f), my = ((float)mouseY / HEIGHT - 0.5f);

        // Camera movement
        
        Vector3f dir = Vector3f(0.0f, 0.0f, 0.0f), dirTemp;
        
        if ((tick) % rpp == 1 || free_mov){
            ma += 0.005 - 1.256 * (ma > 1.256);
            
            if (Keyboard::isKeyPressed(Keyboard::W)) dir = Vector3f(0.0f, 0.0f, 1.0f);
            else if (Keyboard::isKeyPressed(Keyboard::S)) dir = Vector3f(0.0f, 0.0f, -1.0f);
            if (Keyboard::isKeyPressed(Keyboard::A)) dir += Vector3f(-1.0f, 0.0f, 0.0f);
            else if (Keyboard::isKeyPressed(Keyboard::D)) dir += Vector3f(1.0f, 0.0f, 0.0f);
        
//            if (Keyboard::isKeyPressed(Keyboard::I)) MeshPos.z += 0.005f;
//            else if (Keyboard::isKeyPressed(Keyboard::K)) MeshPos.z -= 0.005f;
//            if (Keyboard::isKeyPressed(Keyboard::L)) MeshPos.x += 0.005f;
//            else if (Keyboard::isKeyPressed(Keyboard::J)) MeshPos.x -= 0.005f;
//            if (Keyboard::isKeyPressed(Keyboard::O)) MeshPos.y += 0.005f;
//            else if (Keyboard::isKeyPressed(Keyboard::U)) MeshPos.y -= 0.005f;
//
//            if (Keyboard::isKeyPressed(Keyboard::Y)) MeshScale *= 1.05f;
//            else if (Keyboard::isKeyPressed(Keyboard::H)) MeshScale *= 0.95f;

            if (Keyboard::isKeyPressed(Keyboard::Q)) CameraPos.y -= 0.25f;
            else if (Keyboard::isKeyPressed(Keyboard::E)) CameraPos.y += 0.25f;
            
            
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
        
        fragShader.setUniform("asp_rat", Vector2f(resolution.x / resolution.y / 2.f, 0.5f));
        fragShader.setUniform("sy", resolution.y);
        fragShader.setUniform("ro", CameraPos);
        fragShader.setUniform("mo", MeshPos);
        fragShader.setUniform("ms", MeshScale);
        fragShader.setUniform("u_mouse", Vector2f(mx, my));
        fragShader.setUniform("time", (clock()/(float)CLOCKS_PER_SEC) - int(clock()/(float)CLOCKS_PER_SEC));
        fragShader.setUniform("rand", ((float) rand() / (RAND_MAX)) - 0.5f);
        fragShader.setUniform("alpha", alpha);
        fragShader.setUniform("trace", trace);
        fragShader.setUniform("tick", tick);
        fragShader.setUniform("heavy", heavy);

        RenderStates shader(&fragShader);
        window.draw(rect, shader);

        // Screen updating

        fps.update();
        window.setTitle("Ray Marching v4.0 fps: " + to_string(fps.getFPS()));
        if (!record) window.display();
        
        if (record && tick % rpp == 0){
//            window.display();
            string str_num = to_string(fr_num);
            int z_num = 4 - str_num.size();
            string filename = resourcePath() + "../../../frames/" + string(z_num, '0') + str_num + ".png";
            Texture texture;
            texture.create(window.getSize().x, window.getSize().y);
            texture.update(window);
            texture.copyToImage().saveToFile(filename);
            fr_num++;
            window.display();
            window.clear();
        }
        
        tick++;
    }

    return 0;
}
