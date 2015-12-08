#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <cstring>
#include <iostream>
#include <vector>
#include <map>
#include <assert.h>
#include "SSDB_impl.h"
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#define DBSS_VERSION_MAJOR 1 
#define DBSS_VERSION_MINOR 0 
#define DBSS_VERSION_PATCH 0
#define DBSS_MAKE_VERSION(major, minor, patch) \
    ((major) * 10000 + (minor) * 100 + (patch))
#define DBSS_VERSION \
        DBSS_MAKE_VERSION(DBSS_VERSION_MAJOR, DBSS_VERSION_MINOR, DBSS_VERSION_PATCH) 

typedef struct {
    char const** ptr;
    uint64_t count;
} vec_t;
typedef struct {
    char const *str;
    int64_t num;
} si_t;
/*
do {                                \
    typeof(*p) aszero_ ## p = {0};  \
    p = malloc(sizeof *p);          \
    *p = aszero_ ## p;              \
} while (0)
*/
class DBSS : boost::noncopyable{
    public:
        ssdb::ClientImpl client; 
        ssdb::Status s;
        
        DBSS(char const* ip = "127.0.0.1",int port = 8888){
            std::cout << "DBSS init." << std::endl ;
            connect(ip,port);
        }
        int connect(char const* ip,int port){
            //char const *ip =  "127.0.0.1";
            //int port =  8888;
            int ret = 1;
            client = ssdb::ClientImpl();

            if(!client.connect(ip,port)){
                printf("fail to connect to server!\n");
                return 0;
            }
            std::cout << "ssdb connected" << std::endl;
            return ret;
        }
        int set(char const * key,char const * val){
            s = client.set(std::string(key), std::string(val));
            int ret;
            if(s.ok()){
                std::cout << "set key:" << key << " ok!" << std::endl;
                ret = 1;
            }else{
                ret = -1;
                std::cout << " set key :" << key << " failed!" << std::endl;
            }
            return ret;
        }
        int setx(char const * key,char const * val,int ttl){
            s = client.setx(std::string(key), std::string(val),ttl);
            int ret;
            if(s.ok()){
                std::cout << "set key:" << key << " ok!" << std::endl;
                ret = 1;
            }else{
                ret = -1;
                std::cout << " set key :" << key << " failed!" << std::endl;
            }
            return ret;
        }
        /* after use,delete[] val; */
        int get(char* key,char* val){
            std::string v;
            std::string k = std::string(key);
            std::cout << "in DBSS.cc c++ get key:" << k << std::endl;
            
            //printf("in get client ptr:%p",client);
            s = client.get(k,&v);
            if(s.ok())
            {
                val[v.size() + 1] = 0;
                strcpy(val,v.c_str());
                printf("get key:%s = %s\n",key,val);
            }
            else if(s.not_found())
            {
                strcpy(val,std::string("").c_str());     
            }
              
            return 1;
        }
        /**
         * @param key_start Empty string means no limit.
         * @param key_end Empty string means no limit.
         */
        int keys(vec_t* vec,uint64_t limit, uint64_t vlen,char const *key_start, char const *key_end){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.keys(std::string(key_start),std::string(key_end),limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
        int del(char const* key){
            s = client.del(std::string(key));
            if(s.ok()){
                printf("del ok\n");
            }else{
                printf("del failed\n");
            }
            return s.ok();
        }
        /**
         * Return key-value pairs.
         * The two elements at ret[n] and ret[n+1] form a key-value pair, n=0,2,4,...
         */
        int scan(char const *key_start, char const *key_end,
                uint64_t limit ,uint64_t vlen ,vec_t* vec ){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.scan(std::string(key_start),std::string(key_end),limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
	    int incr(char const *key, int64_t incrby, int64_t *ret){
            s = client.incr(std::string(key),incrby,ret);
            return s.ok();
        }
	    int rscan(char const *key_start, char const *key_end,
		uint64_t limit,uint64_t vlen,vec_t* vec){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.rscan(std::string(key_start),std::string(key_end),limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
	    int multi_get(vec_t *ret,char const **keys,uint64_t size,uint64_t vlen){
            std::vector<std::string> k;
            //std::vector<std::string>* v = new std::vector<std::string>(size);
            std::vector<std::string> v;
            for(uint64_t i = 0; i < size; ++i){
                if(!keys[i]) break;
                k.push_back(std::string(keys[i]));
            }
            s = client.multi_get(k,&v);
            uint64_t i = 0;
            ret->ptr = static_cast<char const**>(malloc(size * vlen));
            std::cout << "vec capacity:" << v.size() << std::endl;
            for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                char const *tmp = (*it).c_str();
                std::cout << "multi_get v:" << tmp << " size :" << strlen(tmp) << std::endl;
                char *cs = new char[strlen(tmp)];
                strcpy(cs,tmp);
                ret->ptr[i] = cs;
                i++;
            }
            ret->count = i;
            return s.ok();
        }
	    int multi_set(char const**  kvs,uint64_t size){
            std::map<std::string,std::string> mkvs;
            for(uint64_t i = 0;i<size;i+=2){
                mkvs.insert(std::pair<std::string,std::string>(std::string(kvs[i]),std::string(kvs[i+1])));
            }
            s = client.multi_set(mkvs);
            return 1; 
        }
	    int multi_del(char const** keys,uint64_t size){
            std::vector<std::string> v;
            for(uint64_t i = 0; i < size; ++i){
                if(!keys[i]) break;
                printf("del key add:%s\n",keys[i]);
                v.push_back(std::string(keys[i]));
            }
            s = client.multi_del(v); 
            return s.ok();
        }
	    int hget(char const *name, char const *key, char *val){
            std::string  tmp;
            std::string *tstr = &tmp;
            
            s = client.hget(std::string(name),std::string(key),tstr);
            printf("cpp hget:%s\n",tmp.c_str());
            strcpy(val,tmp.c_str());
            return s.ok();
        }
	    int hset(char const *name, char const *key, char const *val){
            s = client.hset(std::string(name),std::string(key),std::string(val));
            return s.ok();
        }
	    int hdel(char const *name, char const *key){
            s = client.hdel(std::string(name),std::string(key));
            return s.ok();
        }
	    int hincr(char const *name, char const *key, int64_t incrby, int64_t *ret){
            s = client.hincr(std::string(name),std::string(key),incrby,ret);
            return s.ok();
        }
	    int hsize(char const *name, int64_t *ret){
            s = client.hsize(std::string(name),ret);
            return s.ok();
        }
	    int hclear(char const *name, int64_t *ret){
            s = client.hclear(std::string(name),ret);
            return s.ok();
        }
	    int hkeys(vec_t *vec,char const *name,uint64_t limit,uint64_t vlen, char const *key_start, char const *key_end){
            std::vector<std::string> v;
            try{
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.hkeys(std::string(name),std::string(key_start),std::string(key_end),limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char const *tmp = (*it).c_str();
                    std::cout << "hkeys v:" << tmp << " size :" << strlen(tmp) << std::endl;
                    char *cs = new char[strlen(tmp)];
                    strcpy(cs,tmp);
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
	    int hscan(vec_t *vec,char const *name,uint64_t limit ,uint64_t vlen, char const *key_start, char const *key_end){
            std::vector<std::string> v;
            try{
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.hscan(std::string(name),std::string(key_start),std::string(key_end),limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char const *tmp = (*it).c_str();
                    char *cs = new char[strlen(tmp)];
                    strcpy(cs,tmp);
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
	    int hrscan(vec_t *vec,char const *name,uint64_t limit ,uint64_t vlen, char const *key_start, char const *key_end){
            std::vector<std::string> v;
            try{
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.hrscan(std::string(name),std::string(key_start),std::string(key_end),limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char const *tmp = (*it).c_str();
                    char *cs = new char[strlen(tmp)];
                    strcpy(cs,tmp);
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
	    int multi_hget(vec_t *ret,char const *name,char const **keys,uint64_t size,uint64_t vlen){
            std::vector<std::string> k;
            //std::vector<std::string>* v = new std::vector<std::string>(size);
            std::vector<std::string> v;
            for(uint64_t i = 0; i < size; ++i){
                if(!keys[i]) break;
                k.push_back(std::string(keys[i]));
            }
            s = client.multi_hget(std::string(name),k,&v);
            uint64_t i = 0;
            ret->ptr = static_cast<char const**>(malloc(size * vlen));
            std::cout << "vec capacity:" << v.size() << std::endl;
            for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                char const *tmp = (*it).c_str();
                char *cs = new char[strlen(tmp)];
                strcpy(cs,tmp);
                ret->ptr[i] = cs;
                i++;
            }
            ret->count = i;
            return s.ok();
        }
	    int multi_hset(char const *name,char const **kvs,uint64_t size){
            std::map<std::string,std::string> mkvs;
            for(uint64_t i = 0;i<size;i+=2){
                mkvs.insert(std::pair<std::string,std::string>(std::string(kvs[i]),std::string(kvs[i+1])));
            }
            s = client.multi_hset(std::string(name),mkvs);
            return s.ok(); 
        }

	    int multi_hdel(char const *name, char const **keys,uint64_t size){
            std::vector<std::string> v;
            printf("del size:%lu\n",size);
            for(uint64_t i = 0; i < size; ++i){
                if(!keys[i]) break;
                printf("del key add:%s\n",keys[i]);
                v.push_back(std::string(keys[i]));
            }
            s = client.multi_hdel(std::string(name),v); 
            return s.ok();
             
        }
	    int zget(char const *name, char const *key, int64_t *ret){
            s = client.zget(std::string(name),std::string(key),ret);
            return s.ok();
        }
	    int zset(char const *name, char const *key, int64_t score){
            s = client.zset(std::string(name),std::string(key),score);
            return s.ok();
        }
	    int zdel(char const *name, char const *key){
            s = client.zdel(std::string(name),std::string(key));
            return s.ok();
        }
	    int zincr(char const *name, char const *key, int64_t incrby, int64_t *ret){
            s = client.zincr(std::string(name),std::string(key),incrby,ret);
            return s.ok();
        }
	    int zsize(char const *name, int64_t *ret){
            s = client.zsize(std::string(name),ret);
            return s.ok();
        }
	    int zclear(char const *name, int64_t *ret){
            s = client.zclear(std::string(name),ret);
            return s.ok();
        }
	    int zrank(char const *name, char const *key, int64_t *ret){
            s = client.zrank(std::string(name),std::string(key),ret);
            return s.ok();
        }
	    int zrrank(char const *name, char const *key, int64_t *ret){
            s = client.zrrank(std::string(name),std::string(key),ret);
            return s.ok();
        }
	    int zrange(char const *name,vec_t *vec,uint64_t offset, uint64_t limit,uint64_t vlen){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.zrange(std::string(name),offset,limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
	    int zrrange(char const *name,vec_t *vec,uint64_t offset, uint64_t limit,uint64_t vlen){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                vec->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.zrrange(std::string(name),offset,limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    vec->ptr[i] = cs;
                    i++;
                }
                vec->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                vec->count = 0;
            }
            return s.ok();
        }
	    int zkeys(char const *name, vec_t *ret, char const *key_start,int64_t *score_start, int64_t *score_end,uint64_t limit,uint64_t vlen){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                ret->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                std::cout << "ret:" << ret << ",name:" << name << ",key_start:" << key_start << ",ss:" << score_start << ", se:" << score_end << ", limit:" << limit << std::endl;
                s = client.zkeys(std::string(name),std::string(key_start),score_start,score_end,limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    printf("zkey:%s\n",cs);
                    ret->ptr[i] = cs;
                    i++;
                }
                ret->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                ret->count = 0;
            }
            return s.ok();
        }
	    int zscan(char const *name, vec_t *ret, char const *key_start,int64_t *score_start, int64_t *score_end,uint64_t limit,uint64_t vlen){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                ret->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                std::cout << "ret:" << ret << ",name:" << name << ",key_start:" << key_start << ",ss:" << score_start << ", se:" << score_end << ", limit:" << limit << std::endl;
                s = client.zscan(std::string(name),std::string(key_start),score_start,score_end,limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    printf("zkey:%s\n",cs);
                    ret->ptr[i] = cs;
                    i++;
                }
                ret->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                ret->count = 0;
            }
            return s.ok();
        }
		
	    int zrscan(char const *name, vec_t *ret, char const *key_start,int64_t *score_start, int64_t *score_end,uint64_t limit,uint64_t vlen){
            if(!limit) limit = 10;
            if(!vlen) vlen = 128;
            try{
                std::vector<std::string> v;
                ret->ptr = static_cast<char const**>(malloc(limit * vlen));
                uint64_t i=0;
                s = client.zrscan(std::string(name),std::string(key_start),score_start,score_end,limit,&v);
                for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                    char *cs = new char[vlen];
                    strcpy(cs,(*it).c_str());
                    printf("zrscan:%s\n",cs);
                    ret->ptr[i] = cs;
                    i++;
                }
                ret->count = i;
            }catch (std::exception& e){
                std::cout << "error:" << e.what() << std::endl;
                ret->count = 0;
            }
            return s.ok();
        }
		
	    int multi_zget(char const *name, char const **keys,vec_t *ret,uint64_t size,uint64_t vlen){
            std::vector<std::string> k;
            std::vector<std::string> v;
            for(uint64_t i = 0; i < size; ++i){
                if(!keys[i]) break;
                k.push_back(std::string(keys[i]));
            }
            s = client.multi_zget(std::string(name),k,&v);
            uint64_t i = 0;
            ret->ptr = static_cast<char const**>(malloc(size * vlen));
            std::cout << "multi zget capacity:" << v.size() << std::endl;
            for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                char const *tmp = (*it).c_str();
                char *cs = new char[strlen(tmp)];
                strcpy(cs,tmp);
                ret->ptr[i] = cs;
                i++;
            }
            ret->count = i;
            return s.ok();
        }
	    int multi_zset(char const *name, si_t **kss,uint64_t size){
            std::map<std::string,int64_t> maps;
            for(uint64_t i = 0; i < size; ++i){
                std::cout << "zset get key:" << kss[i]->str << std::endl;
                maps.insert(std::pair<std::string,int64_t>(std::string(kss[i]->str),kss[i]->num));
            }
            s = client.multi_zset(std::string(name),maps);
            return s.ok();
        }
	    int multi_zdel(char const *name, char const **keys,uint64_t size){
            std::vector<std::string> k;
            for(uint64_t i = 0; i < size; ++i){
                if(!keys[i]) break;
                k.push_back(std::string(keys[i]));
            }
            s = client.multi_zdel(std::string(name),k); 
            return s.ok();
        }
	    int qpush(char const *key, char const *val){
            s = client.qpush(std::string(key),std::string(val));
            return s.ok();
        }
	    int qpop(char const *key, char *val){
            std::string v;
            s = client.qpop(std::string(key),&v);
            if(v.c_str())
            {
                strcpy(val,v.c_str());
            }
            return s.ok();
        }
	    int qslice(char const *name,vec_t *ret, int64_t begin, int64_t end,uint64_t vlen){
            std::vector<std::string> v;
            s = client.qslice(std::string(name),begin,end,&v);
            uint64_t i = 0;
            ret->ptr = static_cast<char const**>(malloc(v.size() * vlen));
            std::cout << "multi zget capacity:" << v.size() << std::endl;
            for(std::vector<std::string>::iterator it=v.begin();it!=v.end();++it){
                char const *tmp = (*it).c_str();
                char *cs = new char[strlen(tmp)];
                strcpy(cs,tmp);
                ret->ptr[i] = cs;
                i++;
            }
            ret->count = i;
            return s.ok();
        }
		
};
extern "C" {
    /*
#define SIZE_A 10
    double **get_pointer(){
        double **a = static_cast<double**>(malloc(SIZE_A * sizeof(*a)));
        for (int i = 0; i < SIZE_A; ++i) {
            a[i] = static_cast<double*>(malloc(SIZE_A * sizeof(*a[i])));
            for (int j = 0; j < SIZE_A; ++j) {
                a[i][j] = i*SIZE_A + j;
                printf("%.1f ", a[i][j]);
            }
            printf("\n");
        }

        printf("&a_c = %p\n", (void*)a);
        return a;
    }
*/

    DBSS* DBSS_new(char const *ip,int port){
        return new DBSS(ip,port);
    }

    void DBSS_gc(DBSS *this_){
        delete this_;
    }

    int DBSS_get(DBSS *this_,char* key,void* v){
        printf("get key in DBSS.cc C:%s\n",key);
        char val[255] = "";
        this_->s.ok();
        this_->get(key,val);
        memset(v,0,sizeof(val));
        //*((char*)v) = val;
        strcpy(static_cast<char *>(v),val);
        return 1;
    }

    int DBSS_set(DBSS *this_,char const * key,char const * val){
        int ret;
        ret = this_->set(key,val);
        return ret;
    }

    int DBSS_seti(DBSS *this_,char const * key,int val){
        int ret;
        char str[21];
        sprintf(str,"%d",val);
        ret = this_->set(key,str);
        return ret;
    }

	int DBSS_setxi(DBSS *this_,char const * key, int val, int ttl){
        int ret;
        char str[21];
        sprintf(str,"%d",val);
        ret = this_->setx(key,str,ttl);
        return ret;
    }

	int DBSS_setx(DBSS *this_,char const * key, char const * val, int ttl){
        return  this_->setx(key,val,ttl);
    }

    int DBSS_keys(DBSS *this_,vec_t* vec,uint64_t limit,uint64_t vlen,char const *key_start,char const *key_end){
        return  this_->keys(vec,limit,vlen,key_start,key_end);
    }

    int DBSS_scan(DBSS *this_,vec_t* vec,uint64_t limit ,uint64_t vlen,char const *key_start,char const *key_end){
        int ret = 0;
        ret = this_->scan(key_start,key_end,limit,vlen,vec);
        return ret;
    }

    int DBSS_rscan(DBSS *this_,vec_t* vec,uint64_t limit ,uint64_t vlen,char const *key_start,char const *key_end ){
        int ret = 0;
        ret = this_->rscan(key_start,key_end,limit,vlen,vec);
        return ret;
    }

    int DBSS_del(DBSS *this_,char const* key){
        return this_->del(key);
    }

	int DBSS_incr(DBSS *this_,char const *key, int64_t incrby, int64_t *ret){
        return this_->incr(key,incrby,ret);
    }

	int DBSS_multi_get(DBSS *this_,vec_t *ret,char const **keys,uint64_t size,uint64_t vlen){
        for(int i = 0;i<size;++i)
        {
            printf("multi get key:%s\n",keys[i]);
        }
        return this_->multi_get(ret,keys,size,vlen); 
    }

    int DBSS_multi_set(DBSS *this_,char const **kvs,uint64_t size){
        return this_->multi_set(kvs,size);
    }

    int DBSS_multi_del(DBSS *this_,char const **keys,uint64_t size){
        return this_->multi_del(keys,size);
    }

	int DBSS_hget(DBSS *this_,char const *name, char const *key, char *val){
        return this_->hget(name,key,val);
    }

	int DBSS_hset(DBSS *this_,char const *name, char const *key, char const *val){
        return this_->hset(name,key,val);
    }

	int DBSS_hdel(DBSS *this_,char const *name, char const *key){
        return this_->hdel(name,key);
    }

	int DBSS_hincr(DBSS *this_,char const *name, char const *key, int64_t incrby, int64_t *ret){
        return this_->hincr(name,key,incrby,ret);
    }

    int DBSS_hsize(DBSS *this_,char const *name, int64_t *ret){
        return this_->hsize(name,ret); 
    }

	int DBSS_hclear(DBSS *this_,char const *name, int64_t *ret){
        return this_->hclear(name,ret); 
    }

	int DBSS_hkeys(DBSS *this_,vec_t *vec,char const *name,uint64_t limit,uint64_t vlen, char const *key_start, char const *key_end){
        return  this_->hkeys(vec,name,limit,vlen,key_start,key_end);
    }

	int DBSS_hscan(DBSS *this_,vec_t *vec,char const *name,uint64_t limit,uint64_t vlen, char const *key_start, char const *key_end ){
        return this_->hscan(vec,name,limit,vlen,key_start,key_end);
    }

	int DBSS_hrscan(DBSS *this_,vec_t *vec,char const *name,uint64_t limit,uint64_t vlen, char const *key_start, char const *key_end ){
        return this_->hrscan(vec,name,limit,vlen,key_start,key_end);
    }

	int DBSS_multi_hget(DBSS *this_,vec_t *ret,char const *name,char const **keys,uint64_t size,uint64_t vlen){
        for(int i = 0;i<size;++i)
        {
            printf("multi get key:%s\n",keys[i]);
        }
        return this_->multi_hget(ret,name,keys,size,vlen); 
    }

	int DBSS_multi_hset(DBSS *this_,char const *name,char const **kvs,uint64_t size){
        return this_->multi_hset(name,kvs,size); 
    }

	int DBSS_multi_hdel(DBSS *this_,char const *name, char const **keys,uint64_t size){
        return this_->multi_hdel(name,keys,size); 
    }

	int DBSS_zget(DBSS *this_,char const *name, char const *key, int64_t *ret){
        return this_->zget(name,key,ret);
    }

	int DBSS_zset(DBSS *this_,char const *name, char const *key, int64_t score){
        return this_->zset(name,key,score);
    }
	int DBSS_zdel(DBSS *this_,char const *name, char const *key){
        return this_->zdel(name,key);
    }
	int DBSS_zincr(DBSS *this_,char const *name, char const *key, int64_t incrby, int64_t *ret){
        return this_->zincr(name,key,incrby,ret);
    }
	int DBSS_zsize(DBSS *this_,char const *name, int64_t *ret){
        return this_->zsize(name,ret);
    }
	int DBSS_zclear(DBSS *this_,char const *name, int64_t *ret){
        return this_->zclear(name,ret);
    }
	int DBSS_zrank(DBSS *this_,char const *name, char const *key, int64_t *ret){
        return  this_->zrank(name,key,ret);
    }
	int DBSS_zrrank(DBSS *this_,char const *name, char const *key, int64_t *ret){
        return  this_->zrrank(name,key,ret);
    }
	int DBSS_zrange(DBSS *this_,char const *name,vec_t *ret,uint64_t offset, uint64_t limit,uint64_t vlen){
        return this_->zrange(name,ret,offset,limit,vlen);
    }
	int DBSS_zrrange(DBSS *this_,char const *name,vec_t *ret,uint64_t offset, uint64_t limit,uint64_t vlen){
        return this_->zrrange(name,ret,offset,limit,vlen);
    }
	int DBSS_zkeys(DBSS *this_,char const *name, vec_t *ret, char const *key_start,int64_t score_start, int64_t score_end,uint64_t limit,uint64_t vlen){
        int64_t *ss = &score_start;
        int64_t *se = &score_end;

        return this_->zkeys(name,ret,key_start,ss,se,limit,vlen);
    }
	int DBSS_zscan(DBSS *this_,char const *name, vec_t *ret, char const *key_start,int64_t score_start, int64_t score_end,uint64_t limit,uint64_t vlen){
        int64_t *ss = &score_start;
        int64_t *se = &score_end;

        return this_->zscan(name,ret,key_start,ss,se,limit,vlen);
    }
	int DBSS_zrscan(DBSS *this_,char const *name, vec_t *ret, char const *key_start,int64_t score_start, int64_t score_end,uint64_t limit,uint64_t vlen){
        int64_t *ss = &score_start;
        int64_t *se = &score_end;

        return this_->zrscan(name,ret,key_start,ss,se,limit,vlen);
    }
	int DBSS_multi_zget(DBSS *this_,char const *name, char const **keys,vec_t *ret,uint64_t size,uint64_t vlen){
        return this_->multi_zget(name,keys,ret,size,vlen);        
    }
	int DBSS_multi_zset(DBSS *this_,char const *name, si_t **kss,uint64_t size){
        return this_->multi_zset(name,kss,size); 
    }
	int DBSS_multi_zdel(DBSS *this_,char const *name, char const **keys,uint64_t size){
        return this_->multi_zdel(name,keys,size);
    }
	int DBSS_qpush(DBSS *this_,char const *key, char const *val){
        return this_->qpush(key,val);
    }
	int DBSS_qpop(DBSS *this_,char const *key, char *val){
        return this_->qpop(key,val);
    }
};
