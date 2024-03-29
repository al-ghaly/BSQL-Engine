## CREATE USER & DATABASE
#register user alghaly 12345

#create database college
## LOGIN
login user alghaly 12345
connect database college

## TABLE CREATION
create table students (id/int/pk, name/string/required, city/string, age/int)

create table subjects (name/string/pk, duration/int, instructor/string/unique,hall/string)

create table building (number/int/pk, location/string/required, floors/int)

## DATAINSERTION
insert into students values [id=1,name= Ali,city= Riyadh, age=24]
insert into students values [id=2,name= Alya,city= Jeddah]
insert into students values [id=3,name= Hoda,city= Dammam, age=22]
insert into students values [id=4,name= Omar,city= Makkah, age=23]
insert into students values [id=5,name= Lina,city= Khobar]
insert into students values [id=6,name= Ahmed,city= Madinah, age=21]
insert into students values [id=7,name= Noor, city=Taif, age=22]
insert into students values [id=8,name= Mariam,city= Qassim, age=23]
insert into students values [id=9, name=Tarek, city=Abha, age=24]
insert into students values [id=10,name= Layla, city=Tabuk]
insert into students values [id=11,name= Youssef,city= Jubail, age=22]
insert into students values [id=12,name= Nada, city=Najran, age=23]
insert into students values [id=13,name= Kareem, city=Ahsa, age=21]
insert into students values [id=14,name= Amal, city=Arar, age=22]
insert into students values [id=15,name= Samir, city=Alkhobar, age=23]
insert into students values [id=16,name= Farah, city=AlQatif]
insert into students values [id=17,name= Ziad, city=Hail, age=21]
insert into students values [id=18,name= Rania, city=Buraydah, age=22]
insert into students values [id=19,name= Bilal, city=Riyadh, age=23]
insert into students values [id=20,name= Dina,city= Jeddah]
insert into students values [id=21,name= Salah,city= Dammam]
insert into students values [id=22,name= Mona, city=Makkah]
insert into students values [id=23,name= Raed, city=Khobar]
insert into students values [id=24,name= Leila,city= Madinah]
insert into students values [id=25,name= Jamal, city=Taif]
insert into students values [id=26,name= Rima, city=Qassim]
insert into students values [id=27,name= Khaled, age=]
insert into students values [id=28,name= Hana]
insert into students values [id=29,name= Adel]
insert into students values [id=30,name= Rana]
insert into students values [id=31,name= Hatem, age=23]
insert into students values [id=32,name= Yasmin, age=20]
insert into students values [id=33,name= Majid,  age=22]
insert into students values [id=34,name= Sana, age=21]
insert into students values [id=35,name= Nabil,  age=23]
insert into students values [id=36,name= Fatima,  age=20]
insert into students values [id=37,name= Nasser, age=22]
insert into students values [id=38,name= Nadia]
insert into students values [id=39,name= Jihad,  age=21]
insert into students values [id=40,name= Salma]
insert into students values [id=41,name= Rafik,  age=23]
insert into students values [id=42,name= Rasha, age= 20]
insert into students values [id=43,name= Fadi, age= 22]
insert into students values [id=44,name= Mona,  age=21]
insert into students values [id=45,name= Bassam,age=23]
insert into students values [id=46,name= Amina, age= 20]
insert into students values [id=47,name= Zaki, age=22]
insert into students values [id=48,name= Rana, age=21]
insert into students values [id=49,name= Karim, age= 23]
insert into students values [id=50,name= Lana, age=20]


insert into subjects values [name=Math, instructor=Prof. Johnson]
insert into subjects values [name=Physics, duration=45, instructor=Dr. Brown, hall=Hall B]
insert into subjects values [name=Chemistry, duration=50, instructor=Prof. White]
insert into subjects values [name=Computer Science, duration=55, instructor=Dr. Smith, hall=Hall D]
insert into subjects values [name=Biology, duration=40, instructor=Dr. Anderson, hall=Hall E]
insert into subjects values [name=History, duration=30, instructor=Prof. Davis, hall=Hall F]
insert into subjects values [name=English Literature, instructor=Dr. Taylor, hall=Hall G]
insert into subjects values [name=Economics, duration=45, instructor=Prof. Harris, hall=Hall H]
insert into subjects values [name=Psychology, duration=40, instructor=Dr. Rodriguez]
insert into subjects values [name=Political Science,  instructor=Prof. Martinez]
insert into subjects values [name=Art, duration=25, instructor=Dr. Turner, hall=Hall K]
insert into subjects values [name=Music, duration=30, instructor=Prof. White Jr, hall=Hall L]
insert into subjects values [name=Geography, duration=40, instructor=Dr. Clark, hall=]
insert into subjects values [name=Physical Education, duration=20, instructor=Prof. Baker]
insert into subjects values [name=Statistics, duration=50, instructor=Dr. Hill]
insert into subjects values [name=Philosophy, duration=35, instructor=Prof. Cooper]
insert into subjects values [name=Sociology, duration=30, instructor=Dr. Flores]
insert into subjects values [name=Environmental Science, duration=45, instructor=Prof. Powell]
insert into subjects values [name=Engineering, instructor=Dr. Rogers]
insert into subjects values [name=Marketing, duration=40, instructor=Prof. Wood]

insert into building values [number=101, location=Main Campus]
insert into building values [number=102, location=Science Center, floors=]
insert into building values [number=103, location=Library]
insert into building values [number=104, location=Student Union, floors=2]
insert into building values [number=105, location=Engineering Building, floors=6]
insert into building values [number=106, location=Arts Building]
insert into building values [number=107, location=Sports Complex, floors=3]
insert into building values [number=108, location=Medical Center, floors=]
insert into building values [number=109, location=Business School, floors=3]
insert into building values [number=110, location=Dormitory, floors=8]

update students set [name=Ramy] where id = (4)
update students set [city=Cairo] where name = (Hoda)
update students set [id=51] where name = (Nada)
update students set [age=24] where Name = (Alya)
update students set [age=] where age = (21)
update students set [age=18] where age = ()
update students set [city=Mansoura] where age = (20)
update students set [city=Alex] where Name = (Rana)
update students set [age=25, name=Samy] where Name = (Bassam)

delete from students where age=(18)
delete from students where city=(Taif)
delete from students where city=()
insert into students [name=Rahaf, age=24, id=90,city=Giza]
delete from students where name=(Aly)
delete from students where city=(Abha)
delete from students where city=()
delete from students where age=(23)
delete from students where id=(11)

delete from students where city=()
delete from students where name=(no where)

delete from students where id=()

## ERRORS
# Error due to unique error
update students set [iD=4] where Name = (Alya)
# Error due to pk error
update students set [iD=] where Name = (Alya)
update students set [iD=56, id=57] where Name = (Alya)
update students set [age=56, age=57] where Name = (Alya)
# Error due to required field
update students set [name=, age=57] where Name = (Bassam)





